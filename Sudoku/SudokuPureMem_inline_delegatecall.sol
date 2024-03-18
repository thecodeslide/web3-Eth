// AGPL-3.0-only
// NON-AI AGPL-3.0-only

pragma solidity ^0.8.17;

import "hardhat/console.sol";
//  import "woke/console.sol";
// import "./LibrarySet.sol";

// interface Board {
//   function makeBoard() external pure returns (uint[][] calldata); // TODO??
// }


library SetSudokuLib {
  uint constant INDEX = 9;
  
  struct Set {
    bytes values;
  }

  error duplicateError(uint, bytes32 , bytes4);
  error duplicateError2(bytes1, bytes4);

  function insert(Set memory set, uint key, bytes32 action, uint cellValue) external pure returns (bytes9 rd) {
    // bytes4 errorSelector = duplicateError.selector;
    // inline contain
    assembly {
    
      let result := contains(cellValue, set)
      if eq(result, hex'01') {
        let mem := mload(0x40)

        mstore(mem, hex'011d9462') // duplicateError.selector
        mstore8(add(mem, 0x23),add(cellValue, 1)) // cellvalue
        mstore(add(mem, 0x24) , action)
        mstore(add(mem, 0x44), hex'DEADBEEF')

        revert(mem, 0x64)
        }

        mstore8(add(add(mload(set), 0x20), cellValue), 1)
        rd := mload(add(mload(set), 0x20))

        function contains(_cellValue, _set) -> _result {
          let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
          _result := and(mload(add(add(mload(_set), 0x20), _cellValue)), mask)
        }
    }
  }

   function reset(Set memory set) internal pure {
      assembly {
        mstore(add(mload(set), 0x20), 0)
        let tmp := not(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        tmp := and(tmp, mload(add(mload(set), 0x20)))
        if or(tmp, 0) {
          let frame := mload(0x40)
          mstore(frame, hex"4e487b71") //Panic
          mstore(add(frame, 0x4), 1)
          revert(frame, 0x24)
        }
      }
    }
}


contract SudokuMem {
  
  using SetSudokuLib for SetSudokuLib.Set;
  
  uint8 constant INDEX = 9;
  
  // SetSudokuLib.Set seenList;
  event Log(string indexed message);


  function isValid(uint[INDEX][INDEX] calldata sudokuBoard) public pure returns (uint) {
    // TODO
    // if (!isValidRowsAndColumns(sudokuBoard)) {
    //     return false;
    // }

    SetSudokuLib.Set memory seen;

    assembly {
      seen := mload(0x40)
      mstore(seen, 0)
      mstore(mload(seen), 0x20)
    }

    uint r;
    uint c;
    assembly {
        for {  r := 0 } lt(r, 9) { r := add(r, 1) } {
          for {  c := 0 } lt(c, 9) { c := add(c, 1) } {
            cellValue := calldataload(add(add(mul(0x120, r), sudokuBoard) ,mul(0x20, c)))
            if gt(cellValue, 0) {  //rows
              cellValue := sub(cellValue, 1)
              let seenList := add(mload(seen), 0x20)
              let result := validate(seenList, add(seenList, cellValue))
              //  error duplicateError2(bytes1, bytes4); // f3175e8b
              if eq(result, hex'01') {
                revert(customError(cellValue, hex'DEADBEEF'), 0x44)
                // revert(0,0)
              }
              mstore8(add(seenList, cellValue), 1)
            }

        // cols
            cellValue := calldataload(add( add(mul(0x20, r), sudokuBoard), mul(0x120, c)))
            if gt(cellValue, 0) {  //rows
              cellValue := sub(cellValue, 1)
              let seenList := add(mload(seen), 0x20)
              let result := validate(seenList, add(add(seenList, cellValue), 0xa))
              //  error duplicateError2(bytes1, bytes4); // f3175e8b
              if eq(result, hex'01') {
                revert(customError(cellValue, hex'FDFDFDFD'), 0x44)
              }
              mstore8(add(add(seenList, cellValue), 0xa), 1)
            }

        //blocks
            let i := add(mul(div(r, 3), 3) , div(c, 3))
            let j := add(mul(mod(r,3), 3), mod(c, 3))
            cellValue := calldataload(add(add(mul(0x120, i), sudokuBoard), mul(0x20, j)))
            if gt(cellValue, 0) { 
              cellValue := sub(cellValue, 1)
              let seenList := add(mload(seen), 0x20)
              let tmp := add(add(seenList, cellValue), 0x14)
              let result := validate(seenList, tmp)
              //  error duplicateError2(bytes1, bytes4); // f3175e8b
              if eq(result, hex'01') {
                revert(customError(cellValue, hex'BEBEBEBE'), 0x44)
              }
              mstore8(tmp, 1)
            }
            
          }
          mstore(add(mload(seen), 0x20), 0)
          let mask := not(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
          mask := and(mask, mload(add(mload(seen), 0x20)))
          if or(mask, 0) {
            let frame := mload(0x40)
            mstore(frame, hex"4e487b71") //Panic
            // mstore(add(frame, 0x23), 1)
            mstore(add(frame, 0x4), 1)
            revert(frame, 0x24)
          }
        }

        function validate(list, tmp) -> res {
          let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
          res := and(mload(tmp), mask)
        }

        function customError(cellValue, val) -> cache {
          cache := mload(0x40)
          mstore(cache, hex'f3175e8b')//duplicateError2
          mstore8(add(cache, 0x04), add(cellValue, 1))
          mstore(add(cache, 0x24), val)
        }
    }

    // emit Log(hex'FADEDEAD');
    return 2; // true
  }

  function getLib() public pure returns (address _lib) {
    _lib = address(SetSudokuLib);
  }


  function isValidBlocks(uint[INDEX][INDEX] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;

    assembly {
      mstore(seenListMem, 0)
      let next := seenListMem
      seenListMem := 0
      mstore(0x40, next)

      for { let r := 0 } lt(r, 9) { r := add(r, 3) } {
        for {let c := 0 } lt(c, 9) { c := add(c, 3)} {
          let seenList := mload(seenListMem)
          for { let i:= r} lt(i, add(r,3)) { i:= add(i,1)} {
            for { let j := c } lt(j, add(c,3)) { j := add(j, 1) } {
              let cellValue := calldataload(add(add(mul(0x120, i), sudokuBoard), mul(0x20, j)))

              // need to check!!!
              if gt(cellValue, 9) {
                let mem := mload(0x40)
                // Error(string)
                mstore(mem, shl(0xe5, 0x461bcd))
                mstore(add(mem, 0x04), 0x20)
                mstore(add(mem, 0x24), 0x0f)
                mstore(add(mem, 0x44), "number too high")
                revert(mem, 0x64)
              }

              if gt(cellValue, 0) {  //rows
                cellValue := sub(cellValue, 1)
                
                let mask := hex'ff'
                let tmp := add(seenList, cellValue) // 0x0 + cellValue
                let result := and(mload(tmp), mask)

                if eq(result, hex'01') {
                    let mem := mload(0x40)
                    mstore(mem, hex'f3175e8b')//duplicateError2
                    mstore8(add(mem, 0x04), add(cellValue, 1))
                    mstore(add(mem, 0x24), hex'BEBEBEBE')
                    revert(mem, 0x44)
                }

                mstore8(tmp, 1) // store data
              }
            }
          }

          mstore(seenList, 0) 

          let mask := not(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
          mask := and(mask, mload(seenList))
          if or(mload(mask), 0) {
            let frame := mload(0x40)
            mstore(frame, hex"4e487b71") //Panic
            mstore(add(frame, 0x4), 1)
            revert(frame, 0x24)
          }
          
        }
      }
    } // end asm
    // emit Log("blocks");
    return 2;
  }

//   function isValidBlocksInner(uint[9][9] calldata sudokuBoard) private view {
//     // TODO
//   }

  function isValidColumns(uint[9][9] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
    address _libAdd = address(SetSudokuLib);
    
    for (uint i = 0; i < 9; i++) {
     //   insertListInner(seenListMem, sudokuBoard, "cols", i, _libAdd); 
    }
    return 2;
  }

  function isValidRows(uint[9][9] calldata sudokuBoard) external returns (uint) { // transfer seenlist
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
    address _libAdd = address(SetSudokuLib);
  
    for (uint row = 0; row < 9; row++) {
      insertListInner(seenListMem, sudokuBoard, "rows", row, _libAdd);
    }
    return 2;
  }

  function insertListInner(SetSudokuLib.Set memory seenListMem, uint[9][9] calldata board, bytes32 note, uint position, address _libAdd) private {
    uint cellValue;
    uint len = seenListMem.values.length;
    bytes1 current;
    bytes1 next;

    assembly {
      if iszero(extcodesize(_libAdd)) {
        revert(0,0)
      }
      current := mload(0x40) // init
    }

    for (uint j = 0; j< 9; j++) {
      assembly {
        if eq(note, "rows") {
          cellValue := calldataload(add(add(mul(0x120, position), board), mul(0x20, j)))
        }
        if eq(note, "cols") {
          cellValue := calldataload(add(add(mul(0x20, position),board), mul(0x120, j))) // col
        }
        if gt(cellValue, 9) {
          let mem := mload(0x40)
          // Error(string), which hashes to 0x08c379a0
          mstore(mem, shl(0xe5, 0x461bcd))
          // mstore(mem, hex'08c379a0')
          mstore(add(mem, 0x04), 0x20) 
          mstore(add(mem, 0x24), 0x0f)
          mstore(add(mem, 0x44), "number too high")
          revert(mem, 0x64)
        }
      }
      if(cellValue == 0) {
        continue;
      }
      // TODO asm
      assembly {
        let encoded := current
        mstore(encoded, 0xe4)
        mstore(add(encoded, 0x20), hex"484477da")
        mstore(add(encoded, 0x24), seenListMem)
        mstore(add(encoded, 0x44), j)
        mstore(add(encoded, 0x64), note)
        mstore(add(encoded, 0x84), sub(cellValue, 1))
        mstore(add(encoded, 0xa4), 0x20)
        mstore(add(encoded, 0xc4), len)
        mstore(add(encoded, 0xe4), mload(add(mload(seenListMem), 0x20)))

      // encoded = abi.encodeWithSignature("insert(SetSudokuLib.Set,uint256,bytes32,uint256)",seenListMem ,j, note, cellValue - 1);
        
        let result := delegatecall(gas(), _libAdd, add(encoded, 0x20), mload(encoded), 0, 0)
        if iszero(result) {
          if gt(returndatasize(), 0) {
            let pos := mload(0x40)
            returndatacopy(pos, 0, returndatasize()) // bubbled stuff
            revert(pos, returndatasize())
          }
          let mem := mload(0x40)
          mstore(mem, hex'08c379a0')
          mstore(add(mem, 0x04), 0x20)
          mstore(add(mem, 0x24), 0x6)
          mstore(add(mem, 0x44), "oh no!")
          revert(mem, 0x64)
        }
        returndatacopy(add(mload(seenListMem), 0x20), 0, 0x9)
        next := mload(0x40)
      }
    }

    assertTest(seenListMem);
  }

  function assertTest(SetSudokuLib.Set memory seen) private pure {
    seen.reset();
  }

  // function isValidRowsAndColumns(int8[9][9] calldata sudokuBoard) {
  //   // TODO
  //   //rows
  //   //cols
  // }
}
