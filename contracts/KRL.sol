// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract KartRacer is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20SnapshotUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    UUPSUpgradeable
{
    uint256 public maxSupply; // max Supply
    uint256 internal _10Mil; // 1% of max supply
    uint256 internal _100Mil; // 1% of max supply
    address internal _safe = 0xd8806d66E24b702e0A56fb972b75D24CAd656821;
    mapping(string => bytes32) internal Roles;

    bytes32 public constant CEO = keccak256("CEO");
    bytes32 public constant CTO = keccak256("CTO");
    bytes32 public constant CFO = keccak256("CFO");

    function initialize() public initializer {
        maxSupply = 10000000000 * 10**decimals(); // 10 Billion Tokens ^ 18 decimals
        _100Mil = maxSupply / 100;
        _10Mil = maxSupply / 1000;

        __ERC20_init("Kart Racing League", "KRT");
        __ERC20Burnable_init();
        __ERC20Snapshot_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC20Permit_init("KartRacer");
        __UUPSUpgradeable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _safe);
        _setupRole(CEO, address(0x47c06B50C2a6D28Ce3B130384b19a8929f414030));
        _setupRole(CFO, _safe);
        _setupRole(CTO, msg.sender);
    }

    modifier validate() {
        require(
            hasRole(CEO, msg.sender) ||
                hasRole(CFO, msg.sender) ||
                hasRole(CTO, msg.sender),
            "AccessControl: Address does not have valid Rights"
        );
        _;
    }

    function snapshot() public validate {
        _snapshot();
    }

    function pause() public validate {
        _pause();
    }

    function unpause() public validate {
        _unpause();
    }

    function mint(address to, uint256 amount) public validate {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public validate {
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        override(ERC20Upgradeable, ERC20SnapshotUpgradeable)
        whenNotPaused
    {
        bool _bypass = true;
        uint256 _value = balanceOf(to) + amount;

        if (from == address(0) || to == address(0) || from == _safe) {
            _bypass = false;
        }
        if (_bypass) {
            require(
                _value <= _100Mil,
                "Whale Shock Saftey: A single Account cannot hold more than 1% or 100 Million Tokens"
            );
            require(amount <= _10Mil, "Max Txn Limit of 10 Million Tokens");
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
        bool _bypass = true;
        if (from == address(0) || to == address(0) || from == _safe) {
            _bypass = false;
        }
        if (_bypass) {
            uint256 burnAmount = (amount / 100) / 2;
            _burn(to, burnAmount);
        }
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        require(
            totalSupply() + amount <= maxSupply,
            "Error: Max supply reached, 10 Billion tokens minted."
        );
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._burn(account, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        validate
    {}

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory _S = bytes(source);
        // assembly {
        //     result := mload(add(source, 32))
        // }
        return keccak256(_S);
    }

    function setRole(string memory role, address _add) public onlyRole(CFO) {
        bytes32 _role = stringToBytes32(role);
        Roles[role] = _role;
        _setupRole(_role, _add);
    }
}
