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

  function insert(Set memory set, uint key, bytes32 action, uint cellValue) public pure {
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

        function contains(_cellValue, _set) -> _result {
          let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
          _result := and(mload(add(add(mload(_set), 0x20), _cellValue)), mask)
        }
    }
  }

   function reset(Set memory set) internal pure {
      assembly {
        mstore(add(mload(set), 0x20), 0)
      }

      assert(bytes9(set.values) | 0x0 == 0x0);
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
            stop()
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

  function isValidBlocks(uint[INDEX][INDEX] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;
    uint blockNumber = 0;
    uint count = 0; // for dev. can be removed

    seenListMem.values = new bytes(9);

    uint _rowBlock;
    uint _colBlock;

    uint cellValue;
    for (uint rowBlock = 0; rowBlock < 9; rowBlock += 3) {
      for (uint colBlock = 0; colBlock < 9; colBlock += 3) {
        _rowBlock = rowBlock + 3;
        _colBlock = colBlock + 3;
        for (uint miniRow = rowBlock; miniRow < _rowBlock; miniRow++) {
          for (uint miniCol = colBlock; miniCol < _colBlock; miniCol++) {
            cellValue = sudokuBoard[miniRow][miniCol];
            if (cellValue == 0) {
              continue;
            }
            require(cellValue < 10, "number too high");
            seenListMem.insert(count++, "blocks", cellValue -1);
            
          }
        }
        count = 0; // for dev. can be removed
        blockNumber++;

        seenListMem.reset();
      }
    }
    // emit Log("blocks");
    return 2;
  }


//   function isValidBlocksInner(uint[9][9] calldata sudokuBoard) private view {
//     // TODO
//   }

  function isValidRows(uint[9][9] calldata sudokuBoard) external pure returns (uint) { // transfer seenlist
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
    address _libAdd = address(SetSudokuLib);
  
    for (uint row = 0; row < 9; row++) {
      insertListInner(seenListMem, board, "rows", row, _libAdd);
    }
    return 2;
  }

  function isValidColumns(uint[9][9] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
    address _libAdd = address(SetSudokuLib);
    
    for (uint i = 0; i < 9; i++) {
        insertListInner(seenListMem, sudokuBoard, "cols", i, _libAdd); 
    }
    return 2;
  }

  function insertListInner(SetSudokuLib.Set memory seenListMem, uint[9][9] calldata board, bytes32 note, uint position) private pure {
    uint cellValue;

    for (uint j = 0; j< 9; j++) {
      if (note == "rows") {
        cellValue = board[position][j];
      }
      else { //col
        cellValue = board[j][position] ;
      }
      if(cellValue == 0) { // empty cell
        continue;
      }
      require(cellValue < 10, "number too high");
      
      seenListMem.insert(j, note, cellValue - 1);
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
