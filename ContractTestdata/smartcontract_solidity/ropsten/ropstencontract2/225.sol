/**
 *Submitted for verification at Etherscan.io on 2019-08-09
*/

pragma solidity >=0.4.25 <0.6.0;


library BlockNumbIntsLib {
    
    
    
    struct Entry {
        uint256 blockNumber;
        int256 value;
    }

    struct BlockNumbInts {
        Entry[] entries;
    }

    
    
    
    function currentValue(BlockNumbInts storage self)
    internal
    view
    returns (int256)
    {
        return valueAt(self, block.number);
    }

    function currentEntry(BlockNumbInts storage self)
    internal
    view
    returns (Entry memory)
    {
        return entryAt(self, block.number);
    }

    function valueAt(BlockNumbInts storage self, uint256 _blockNumber)
    internal
    view
    returns (int256)
    {
        return entryAt(self, _blockNumber).value;
    }

    function entryAt(BlockNumbInts storage self, uint256 _blockNumber)
    internal
    view
    returns (Entry memory)
    {
        return self.entries[indexByBlockNumber(self, _blockNumber)];
    }

    function addEntry(BlockNumbInts storage self, uint256 blockNumber, int256 value)
    internal
    {
        require(
            0 == self.entries.length ||
        blockNumber > self.entries[self.entries.length - 1].blockNumber,
            "Later entry found [BlockNumbIntsLib.sol:62]"
        );

        self.entries.push(Entry(blockNumber, value));
    }

    function count(BlockNumbInts storage self)
    internal
    view
    returns (uint256)
    {
        return self.entries.length;
    }

    function entries(BlockNumbInts storage self)
    internal
    view
    returns (Entry[] memory)
    {
        return self.entries;
    }

    function indexByBlockNumber(BlockNumbInts storage self, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entries.length, "No entries found [BlockNumbIntsLib.sol:92]");
        for (uint256 i = self.entries.length - 1; i >= 0; i--)
            if (blockNumber >= self.entries[i].blockNumber)
                return i;
        revert();
    }
}
