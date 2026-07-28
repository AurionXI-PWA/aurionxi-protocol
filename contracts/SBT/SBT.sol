// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SBT is ERC721, AccessControl, EIP712 {
    using ECDSA for bytes32;
    using Strings for uint256;

    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant METADATA_ROLE = keccak256("METADATA_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // EIP-5192 interface id: locked(uint256)
    bytes4 private constant _INTERFACE_ID_ERC5192 = 0xb45a3c0e;

    enum AIDType {
        None,
        Retail,
        Institution,
        Hybrid
    }

    struct AIDData {
        uint8 aidType;
        bytes32 verificationHash;
        uint64 issuedAt;
    }

    struct MintRequest {
        address to;
        uint8 aidType;
        bytes32 verificationHash;
        string uri;
        uint256 deadline;
        uint256 nonce;
    }

    bytes32 private constant _MINTREQUEST_TYPEHASH =
        keccak256(
            "MintRequest(address to,uint8 aidType,bytes32 verificationHash,string uri,uint256 deadline,uint256 nonce)"
        );

    uint256 private _nextTokenId = 1;
    uint256 private _totalActiveSupply;
    uint256 private _totalIssued;

    string private _baseTokenURI;

    mapping(address => uint256) private _tokenIdOf;
    mapping(uint256 => AIDData) private _aidData;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) public nonces;

    event IssuerUpdated(address indexed issuer, bool enabled);
    event MetadataManagerUpdated(address indexed manager, bool enabled);
    event BurnerUpdated(address indexed burner, bool enabled);
    event BaseURIUpdated(string baseURI);

    event AIDMinted(
        address indexed user,
        uint256 indexed tokenId,
        uint8 aidType,
        bytes32 verificationHash,
        string uri
    );

    event AIDMintedWithSignature(
        address indexed issuer,
        address indexed user,
        uint256 indexed tokenId,
        uint8 aidType,
        bytes32 verificationHash,
        string uri
    );

    event AIDUpdated(
        address indexed user,
        uint256 indexed tokenId,
        uint8 aidType,
        bytes32 verificationHash,
        string uri
    );

    event AIDRevoked(address indexed user, uint256 indexed tokenId);
    event Locked(uint256 tokenId);

    error ZeroAddress();
    error NotAuthorized();
    error AlreadyHasAID(address user);
    error AIDNotFound(address user);
    error InvalidAIDType();
    error SignatureExpired();
    error InvalidIssuer();
    error InvalidNonce();
    error SoulboundTransferDisabled();

    constructor(address admin)
        ERC721("AurionXI AID", "AID")
        EIP712("AurionXI AID", "1")
    {
        if (admin == address(0)) {
            revert ZeroAddress();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, admin);
        _grantRole(METADATA_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
    }

    function setIssuer(address issuer, bool enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (issuer == address(0)) {
            revert ZeroAddress();
        }

        if (enabled) {
            _grantRole(ISSUER_ROLE, issuer);
        } else {
            _revokeRole(ISSUER_ROLE, issuer);
        }

        emit IssuerUpdated(issuer, enabled);
    }

    function setMetadataManager(address manager, bool enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (manager == address(0)) {
            revert ZeroAddress();
        }

        if (enabled) {
            _grantRole(METADATA_ROLE, manager);
        } else {
            _revokeRole(METADATA_ROLE, manager);
        }

        emit MetadataManagerUpdated(manager, enabled);
    }

    function setBurner(address burner, bool enabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (burner == address(0)) {
            revert ZeroAddress();
        }

        if (enabled) {
            _grantRole(BURNER_ROLE, burner);
        } else {
            _revokeRole(BURNER_ROLE, burner);
        }

        emit BurnerUpdated(burner, enabled);
    }

    function setBaseURI(string calldata baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseURI_;

        emit BaseURIUpdated(baseURI_);
    }

    function issuerMint(
        address to,
        uint8 aidType,
        bytes32 verificationHash,
        string calldata uri
    ) external onlyRole(ISSUER_ROLE) returns (uint256 tokenId) {
        tokenId = _mintAID(to, aidType, verificationHash, uri);

        emit AIDMinted(to, tokenId, aidType, verificationHash, uri);
    }

    function mintWithSignature(
        MintRequest calldata req,
        bytes calldata signature
    ) external returns (uint256 tokenId) {
        if (req.deadline != 0 && req.deadline < block.timestamp) {
            revert SignatureExpired();
        }

        bytes32 structHash = keccak256(
            abi.encode(
                _MINTREQUEST_TYPEHASH,
                req.to,
                req.aidType,
                req.verificationHash,
                keccak256(bytes(req.uri)),
                req.deadline,
                req.nonce
            )
        );

        address signer = _hashTypedDataV4(structHash).recover(signature);

        if (!hasRole(ISSUER_ROLE, signer)) {
            revert InvalidIssuer();
        }

        if (nonces[signer] != req.nonce) {
            revert InvalidNonce();
        }

        nonces[signer]++;

        tokenId = _mintAID(
            req.to,
            req.aidType,
            req.verificationHash,
            req.uri
        );

        emit AIDMintedWithSignature(
            signer,
            req.to,
            tokenId,
            req.aidType,
            req.verificationHash,
            req.uri
        );
    }

    function updateAID(
        address user,
        uint8 aidType,
        bytes32 verificationHash,
        string calldata uri
    ) external onlyRole(METADATA_ROLE) {
        if (!_isValidAIDType(aidType)) {
            revert InvalidAIDType();
        }

        uint256 tokenId = tokenIdOf(user);

        _aidData[tokenId].aidType = aidType;
        _aidData[tokenId].verificationHash = verificationHash;

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        emit AIDUpdated(user, tokenId, aidType, verificationHash, uri);
    }

    function revokeAID(address user) external onlyRole(BURNER_ROLE) {
        uint256 tokenId = tokenIdOf(user);

        delete _tokenIdOf[user];
        delete _aidData[tokenId];
        delete _tokenURIs[tokenId];

        _totalActiveSupply--;

        _burn(tokenId);

        emit AIDRevoked(user, tokenId);
    }

    function totalActiveSupply() external view returns (uint256) {
        return _totalActiveSupply;
    }

    function totalIssued() external view returns (uint256) {
        return _totalIssued;
    }

    function tokenIdOf(address user) public view returns (uint256) {
        uint256 tokenId = _tokenIdOf[user];

        if (tokenId == 0 || _ownerOf(tokenId) != user) {
            revert AIDNotFound(user);
        }

        return tokenId;
    }

    function aidTypeOf(address user) public view returns (uint8) {
        uint256 tokenId = tokenIdOf(user);

        return _aidData[tokenId].aidType;
    }

    function getAIDType(address user) external view returns (string memory) {
        uint8 aidType = aidTypeOf(user);

        if (aidType == uint8(AIDType.Retail)) {
            return "Retail";
        }

        if (aidType == uint8(AIDType.Institution)) {
            return "Institution";
        }

        if (aidType == uint8(AIDType.Hybrid)) {
            return "Hybrid";
        }

        return "None";
    }

    function isRetailAID(address user) external view returns (bool) {
        if (balanceOf(user) == 0) {
            return false;
        }

        uint8 aidType = aidTypeOf(user);

        return aidType == uint8(AIDType.Retail) ||
            aidType == uint8(AIDType.Hybrid);
    }

    function isInstitutionAID(address user) external view returns (bool) {
        if (balanceOf(user) == 0) {
            return false;
        }

        uint8 aidType = aidTypeOf(user);

        return aidType == uint8(AIDType.Institution) ||
            aidType == uint8(AIDType.Hybrid);
    }

    function verificationHashOf(address user) external view returns (bytes32) {
        uint256 tokenId = tokenIdOf(user);

        return _aidData[tokenId].verificationHash;
    }

    function aidDataOf(address user)
        external
        view
        returns (
            uint256 tokenId,
            uint8 aidType,
            bytes32 verificationHash,
            uint64 issuedAt,
            string memory uri
        )
    {
        tokenId = tokenIdOf(user);

        AIDData memory data = _aidData[tokenId];

        return (
            tokenId,
            data.aidType,
            data.verificationHash,
            data.issuedAt,
            tokenURI(tokenId)
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        ownerOf(tokenId);

        string memory storedURI = _tokenURIs[tokenId];

        if (bytes(storedURI).length > 0) {
            return storedURI;
        }

        if (bytes(_baseTokenURI).length == 0) {
            return "";
        }

        return string.concat(_baseTokenURI, tokenId.toString(), ".json");
    }

    function locked(uint256 tokenId) external view returns (bool) {
        ownerOf(tokenId);

        return true;
    }

    function approve(address, uint256) public pure override {
        revert SoulboundTransferDisabled();
    }

    function setApprovalForAll(address, bool) public pure override {
        revert SoulboundTransferDisabled();
    }

    function getApproved(uint256) public pure override returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return interfaceId == _INTERFACE_ID_ERC5192 ||
            super.supportsInterface(interfaceId);
    }

    function _mintAID(
        address to,
        uint8 aidType,
        bytes32 verificationHash,
        string memory uri
    ) internal returns (uint256 tokenId) {
        if (to == address(0)) {
            revert ZeroAddress();
        }

        if (!_isValidAIDType(aidType)) {
            revert InvalidAIDType();
        }

        if (balanceOf(to) > 0) {
            revert AlreadyHasAID(to);
        }

        tokenId = _nextTokenId;
        _nextTokenId++;

        _tokenIdOf[to] = tokenId;

        _aidData[tokenId] = AIDData({
            aidType: aidType,
            verificationHash: verificationHash,
            issuedAt: uint64(block.timestamp)
        });

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        _totalActiveSupply++;
        _totalIssued++;

        _safeMint(to, tokenId);

        emit Locked(tokenId);
    }

    function _isValidAIDType(uint8 aidType) internal pure returns (bool) {
        return aidType >= uint8(AIDType.Retail) &&
            aidType <= uint8(AIDType.Hybrid);
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);

        if (from != address(0) && to != address(0)) {
            revert SoulboundTransferDisabled();
        }

        return super._update(to, tokenId, auth);
    }
}