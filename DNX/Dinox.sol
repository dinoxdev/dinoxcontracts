// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dinox is ERC721, ERC721Enumerable, Ownable, IERC721Receiver {
    constructor() ERC721("DINOX", "DNX") {}

    mapping (uint256 => uint256) private _parentsA;
    mapping (uint256 => uint256) private _parentsB;
    mapping (uint256 => bool) private _isParent;
    mapping (uint256 => uint16) private _gs;

    mapping (uint16 => uint16) private _gsSupply;    
    mapping (uint16 => uint16) private _gsCap;
    mapping (uint16 => uint256) private _gsStartTokenId;
    mapping (uint16 => uint16) private _gsBracketSizes;
    mapping (uint16 => uint16) private _gsBrackets;
    mapping (uint16 => uint256) private _gsPrices;
    mapping (uint16 => uint) private _gsStartTime;    
    mapping (uint16 => uint) private _gsEndTime;
    mapping (uint16 => uint256) private _postgsPrice;

    address private _breeder;
    bool private _breedingEnabled = false;
    bool private _salesEnabled = false;
    
    function buyDNX(uint16 gid, uint16 count) public payable {
        require(_salesEnabled, "E01");
        require(block.timestamp > _gsStartTime[gid], "E02");
        require(block.timestamp < _gsEndTime[gid], "E03");
        require(count > 0 && count <= 10, "E04");
        require(_gsSupply[gid] + count <= _gsCap[gid], "E05");
        require(msg.value >= calculatePrice(gid,count), "E06");

        for (uint i = 0; i < count; i++) {
            uint mintIndex = _gsSupply[gid] + _gsStartTokenId[gid] + i;
            _safeMint(msg.sender, mintIndex);
            _gs[mintIndex] = gid;
        }
        _gsSupply[gid] += count;
    }
    
    function lateBuyDNX(uint16 gid, uint16 count) public payable {
        require(_salesEnabled, "E01");
        require(block.timestamp > _gsEndTime[gid], "E12");
        require(count > 0 && count <= 10, "E04");
        require(_postgsPrice[gid] > 0, "E07");
        require(_gsSupply[gid] + count <= _gsCap[gid], "E05");
        require(msg.value >= _postgsPrice[gid]*count, "E06");

        for (uint i = 0; i < count; i++) {
            uint mintIndex = _gsSupply[gid] + _gsStartTokenId[gid] + i;
            _safeMint(msg.sender, mintIndex);
            _gs[mintIndex] = gid;
        }
        _gsSupply[gid] += count;
    }
    
    function breedDNX(uint256 parentA, uint256 parentB, uint256 tokenId, uint16 resolvedGen, address to) public {
        require(_breedingEnabled, "E08");
        require(msg.sender == _breeder, "E09");
        require(ownerOf(parentA) == to && ownerOf(parentB) == to, "E10");
        require(!_isParent[parentA] && !_isParent[parentB], "E11");
        _safeMint(to, tokenId);
        _parentsA[tokenId] = parentA;
        _parentsB[tokenId] = parentB;
        _isParent[parentA] = true;        
        _isParent[parentB] = true;
        _gs[tokenId] = resolvedGen;
    }
    
    function calculatePrice(uint16 gid, uint16 count) public view returns (uint256) {
        require(block.timestamp > _gsStartTime[gid], "E02");
        require(block.timestamp < _gsEndTime[gid], "E03");
        require(_gsSupply[gid] < _gsCap[gid], "E13");

        uint16 sb = 0;
        uint16 eb = 0;
        uint16 i;
        for (i = 0; i <= gid; i++) {
            if (i < gid) {
                sb += _gsBracketSizes[i];
            }
            eb += _gsBracketSizes[i];
        }
        
        uint16 pi = 0;
        uint256 sf = 0;
        for (i = sb; i < eb; i++) {
            sf += _gsBrackets[i];
            if (sf > _gsSupply[gid]) {
                pi = i+1;
                break;
            }
        }
        
        require(pi > 0, "E14");
        
        return _gsPrices[pi-1]*count;
    }
    
    function reserveForGiveaway(uint16 gid, uint16 count) public onlyOwner {
        for (uint i = 0; i < count; i++) {
            uint mintIndex = _gsSupply[gid] + _gsStartTokenId[gid] + i;
            _safeMint(msg.sender, mintIndex);
            _gs[mintIndex] = gid;
        }
        _gsSupply[gid] += count;
    }
    
    function changeGSCap(uint16 gid, uint16 supply) public onlyOwner {
        _gsCap[gid] = supply;
        _gsSupply[gid] = 0;
    }
    
    function changeGSStartToken(uint16 gid, uint256 tokenId) public onlyOwner {
        _gsStartTokenId[gid] = tokenId;
    }
    
    function changeGSBracketSizes(uint16 gid, uint16 bracketSize) public onlyOwner {
        _gsBracketSizes[gid] = bracketSize;
    }
    
    function changeGSBrackets(uint16 bracketId, uint16 bracketTokenCount) public onlyOwner {
        _gsBrackets[bracketId] = bracketTokenCount;
    }
    
    function changeGSBracketPrice(uint16 bid, uint256 p) public onlyOwner {
        _gsPrices[bid] = p;
    }
    
    function changeGSPostPrice(uint16 gid, uint256 p) public onlyOwner {
        _postgsPrice[gid] = p;
    }
    
    function changeGSTime(uint16 gid, uint st, uint et) public onlyOwner {
        _gsStartTime[gid] = st;
        _gsEndTime[gid] = et;
    }
    
    function toggleSales() public onlyOwner {
        _salesEnabled = !_salesEnabled;
    }
    
    function toggleBreeding() public onlyOwner {
        _breedingEnabled = !_breedingEnabled;
    }
    
    function getPA(uint256 tokenId) public view returns (uint256) {
        return _parentsA[tokenId];
    }
    
    function getPB(uint256 tokenId) public view returns (uint256) {
        return _parentsB[tokenId];
    }
    
    function getIsP(uint256 tokenId) public view returns (bool) {
        return _isParent[tokenId];
    }
    
    function getTG(uint256 tokenId) public view returns (uint16) {
        return _gs[tokenId];
    }
    
    function getGSSupply(uint16 gid) public view returns (uint16) {
        return _gsSupply[gid];
    }
    
    function getGSCap(uint16 gid) public view returns (uint16) {
        return _gsCap[gid];
    }
    
    function setBreederAddress(address breeder) public onlyOwner {
        _breeder = breeder;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
