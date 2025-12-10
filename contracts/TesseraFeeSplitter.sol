// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TesseraFeeSplitter is AccessControl, ReentrancyGuard {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant SPLITTER_ROLE = keccak256("SPLITTER_ROLE");

    IERC20 public immutable token;

    address public publisher;
    address public devs;

    uint16 public publisherBps; //0-10000
    uint16 public devsBps; //0-10000

    event Distributed(
        uint256 total,
        uint256 publisherAmount,
        uint256 devsAmount
    );
    event PercentagesUpdated(uint16 publisherBps, uint16 devsBps);
    event RecipientsUpdated(address publisher, address devs);
    event EmergencyWithdraw(address recipient, uint256 amount);

    constructor (
        address _token,
        address _publisher,
        address _devs,
        uint16  _publisherBps,
        uint16  _devsBps,
        address admin
    ) {
        require(_token != address(0), "token=0");
        require(_publisher != address(0), "pub=0");
        require(_devs != address(0), "devs=0");
        require(_publisherBps + _devsBps == 10000, "bps sum != 10000");

        token = IERC20(token);

        publisher = _publisher;
        devs = _devs;
        publisherBps = _publisherBps;
        devsBps = _devsBps;

        //Admin setup
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        //Allow publisher + devs to call distribute
        _grantRole(SPLITTER_ROLE, _publisher);
        _grantRole(SPLITTER_ROLE, _devs);
    }

    /**
     * @notice Only publisher or devs can call distribute.
     */
    function distribute() 
        public
        nonReentrant 
        onlyRole(SPLITTER_ROLE)
    {
        uint256 bal = token.balanceOf(address(this));
        require(bal > 0, "no tokens");

        uint256 publisherShare = (bal * publisherBps) / 10000;
        uint256 devShare = bal - publisherShare;

        require(token.transfer(publisher, publisherShare), "pub fail");
        require(token.transfer(devs, devShare), "dev fail");

        emit Distributed(bal, publisherShare, devShare);
    }

    /**
     * @notice Admin can emergency withdraw
     */
    function emergencyWithdraw()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        nonReentrant
    {
        uint256 bal = token.balanceOf(address(this));
        require(bal > 0, "no tokens");

        require(token.transfer(msg.sender, bal), "withdraw fail");

        emit EmergencyWithdraw(msg.sender, bal);
    }
         
}