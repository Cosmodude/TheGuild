// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../interfaces/IRewarder.sol";
import "../interfaces/IReferralHandler.sol";
import "../interfaces/INexus.sol";
import "../interfaces/ITaxManager.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Mock Rewarder for testing
contract MockRewarder is IRewarder {
    using SafeERC20 for IERC20;

    address public steward;
    INexus nexus;

    event RewardClaimed(
        address indexed solverAccount,
        address escrow,
        uint256 solverReward
    );
    event ResolutionProccessed(
        uint32 indexed seekerId,
        uint32 indexed solverId,
        uint8 solverShare
    );

    constructor(address _steward) {
        steward = _steward;
    }

    modifier onlySteward() {
        require(msg.sender == steward, "only Steward");
        _;
    }

    function getTaxManager() public view returns (ITaxManager) {
        address taxManager = INexus(nexus).taxManager();
        return ITaxManager(taxManager);
    }

    function handleRewardNative(uint32) public payable {
        address escrow = msg.sender;
        require(escrow.balance == 0, "Escrow not empty");

        (bool success, ) = payable(tx.origin).call{value: msg.value}("");
        require(success, "Solver reward pay error");

        emit RewardClaimed(tx.origin, escrow, msg.value);
    }

    function handleRewardToken(
        address token,
        uint32 solverId,
        uint256 amount
    ) external {

    }

    function calculateSeekerTax(uint256 _paymentAmount)
        public
        view
        returns (uint256 platformTax_, uint256 referralTax_)
    {
        ITaxManager taxManager = getTaxManager();
        (platformTax_, referralTax_) = _calculateSeekerTax(taxManager, _paymentAmount);
    }

    function _calculateSeekerTax(ITaxManager _taxManager, uint256 _paymentAmount) 
        internal 
        view
        returns 
    (
        uint256 platformTax_, 
        uint256 referralTax_
    ){
        ITaxManager.SeekerFees memory seekerFees = _taxManager.getSeekerFees();
        uint256 taxRateDivisor = _taxManager.taxBaseDivisor();

        referralTax_ = (_paymentAmount * seekerFees.referralRewards) /
            taxRateDivisor;

        platformTax_ = (_paymentAmount * seekerFees.platformRevenue) /
            taxRateDivisor;

        return (referralTax_, platformTax_);
    }

    function handleSeekerTaxNative(
        uint32 solverId,
        uint256 referralTax,
        uint256 platformTax
    ) external payable {
    }

    function handleSeekerTaxToken(
        uint32 solverId,
        uint256 referralTax,
        uint256 platformTax,
        address token
    ) external {
    }

    function proccessResolutionNative(
        uint32 seekerId,
        uint32 solverId,
        uint8 solverShare
    ) external payable override {
        emit ResolutionProccessed(seekerId, solverId, solverShare);
    }

    function proccessResolutionToken(
        uint32 seekerId,
        uint32 solverId,
        uint8 solverShare,
        address
    ) external override {
        emit ResolutionProccessed(seekerId, solverId, solverShare);
    }

    function rewardReferrers(
        address handler,
        uint256 taxValue,
        uint256 taxDivisor
    ) internal {
        
    }

    function recoverTokens(
        address _token,
        address benefactor
    ) external onlySteward {
        if (_token == address(0)) {
            (bool sent, ) = payable(benefactor).call{
                value: address(this).balance
            }("");
            require(sent, "Send error");
            return;
        }
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(benefactor, tokenBalance);
        return;
    } 
}