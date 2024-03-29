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

  function insert(Set memory set, uint key, bytes32 action, uint cellValue) internal pure {
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

  // function contains(Set memory set, uint cellValue) internal pure returns(bytes1 result) {
  //  assembly {
  //    result := mload(add(add(mload(set), 0x20), cellValue))
  //  }
  //}

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


  function isValid(uint[INDEX][INDEX] calldata sudokuBoard) external pure returns (uint) {
    // TODO
    // if (!isValidRowsAndColumns(sudokuBoard)) {
    //     return false;
    // }

    SetSudokuLib.Set memory seen;
    seen.values = new bytes(32);

    // rowList.values = new bytes(9);
    // colList.values = new bytes(9);
    // blockList.values = new bytes(9);

     assembly {
      let pos := mload(seen) // 0x80 -> 0xa0
      mstore(pos, 0)
      mstore(seen, 0) 
      mstore(mload(seen), 0x20)
      mstore(0x40, pos) //0xa0
    }

    uint r;
    uint c;
    assembly {
        let size := mul(0x20, 9) //0x120
        let endArr := mul(size, 9) // 0xA20

        for {  r := sudokuBoard } lt(r, endArr) { r := add(r, size) } {
          for {  c := 0 } lt(c, 9) { c := add(c, 1) } {
            let cellValue := calldataload(add(r ,mul(0x20, c)))
            if gt(cellValue, 0) {  //rows
              cellValue := sub(cellValue, 1)
            
              let seenList := add(mload(seen), 0x20)
              let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
              let result := and(mload(add(seenList, cellValue)), mask)
              //  error duplicateError2(bytes1, bytes4); // f3175e8b
              if eq(result, hex'01') {
                let mem := mload(0x40)
                mstore(mem, hex'f3175e8b')//duplicateError2
                mstore8(add(mem, 0x04), add(1, cellValue))
                mstore(add(mem, 0x24), hex'DEADBEEF')
                revert(mem, 0x44)
                // revert(0,0)
              }
              mstore8(add(seenList, cellValue), 1)
            }
          }
          mstore(add(mload(seen), 0x20), 0)
        }

        // cols
        for {  c := 0 } lt(c, 5) { c := add(c, 1) } { //cols
          for {  r := 0x04 } lt(r, endArr) { r := add(r, size) } {
            let cellValue := calldataload(add( r, mul(0x20, c)))
            if gt(cellValue, 0) { 
              cellValue := sub(cellValue, 1)
            
              let seenList := add(mload(seen), 0x20)
              let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
              let result := and(mload(add(seenList, cellValue)), mask)
              //  error duplicateError2(bytes1, bytes4); // f3175e8b
              if eq(result, hex'01') {
                let mem := mload(0x40)
                mstore(mem, hex'f3175e8b')//duplicateError2
                mstore8(add(mem, 0x04), add(cellValue, 1))
                mstore(add(mem, 0x24), hex'FDFDFDFD')
                revert(mem, 0x44)
                // revert(0,0)
              }
              mstore8(add(seenList, cellValue), 1)
            }
          }
          mstore(add(mload(seen), 0x20), 0)
        }

        //blocks
        for { r := 0} lt(r, 9) { r := add(r, 1)} {
          for { c := 0 } lt(c, 9) { c := add(c, 1) } {
            let i := add(mul(div(r, 3), 3) , div(c, 3))
            let j := add(mul(mod(r,3), 3), mod(c, 3))
            let cellValue := calldataload(add(add(mul(0x120, i), sudokuBoard), mul(0x20, j)))
            if gt(cellValue, 0) {
              cellValue := sub(cellValue, 1)
            
              let seenList := add(mload(seen), 0x20)
              let mask := 0xFF00000000000000000000000000000000000000000000000000000000000000
              let result := and(mload(add(seenList, cellValue)), mask)
              if eq(result, hex'01') {
                let mem := mload(0x40)
                mstore(mem, hex'f3175e8b')//duplicateError2
                mstore8(add(mem, 0x04), add(cellValue, 1))
                mstore(add(mem, 0x24), hex'BEBEBEBE')
                revert(mem, 0x44)
              }
              mstore8(add(seenList, cellValue), 1)
            }
          }
          mstore(add(mload(seen), 0x20), 0)
        }
    }
    // emit Log(hex'FADEDEAD');
    return 2; // true
  }

//   function insertBlockInner () {
        // TODO
//   }

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

  function isValidRows(uint[9][9] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
  
  
    for (uint row = 0; row < 9; row++) {
      insertListInner(seenListMem, sudokuBoard, "rows", row);
    }
    return 2;
  }

  function isValidColumns(uint[9][9] calldata sudokuBoard) external pure returns (uint) {
    SetSudokuLib.Set memory seenListMem;
    seenListMem.values = new bytes(9);
    
    for (uint i = 0; i < 9; i++) {
        insertListInner(seenListMem, sudokuBoard, "cols", i);
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
