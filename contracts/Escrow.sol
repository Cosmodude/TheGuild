pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Escrow {
  using SafeERC20 for IERC20;

  address[] public tokens;
  address public governance; // who is it?

  modifier onlyGov() {
    require(msg.sender == governance, "only gov");
    _;
  }

  constructor (address[] _tokens) public {
    tokens = _tokens;
    governance = msg.sender;
  }

  function approve(address _token, address to, uint256 amount) public onlyGov {
    IERC20(_token).approve(to, 0);
    IERC20(_token).approve(to, amount);
  }

  function transfer(address _token, address to, uint256 amount) public onlyGov {
    IERC20(_token).transfer(to, amount);
  }

  // This exists to mirror the interaction of how the perpetual staking pool would
  function notifySecondaryTokens(uint256 amount) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);
  }

  function setGovernance(address account) external onlyGov {
    governance = account;
  }
}