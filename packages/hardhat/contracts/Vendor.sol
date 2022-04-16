pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {

    YourToken public yourToken;

  constructor(address tokenAddress) {
    yourToken = YourToken(tokenAddress);
  }


// buyToken function with event to emit for frontend
// Anyone can buy tokens as long as they supply enough ETH and vendor address has enough yourToken available

event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountPurchased);

uint256 public constant tokensPerEth = 100;

function buyTokens() public payable returns (uint256) {
  
  // Must buy value thats greater than 0 and makes sure that vendor has enough tokens left 
  
  require(msg.value > 0, "No value is being sent");
  address buyer = msg.sender;
  uint256 amountOfETH = msg.value;  
  uint256 amountPurchased = msg.value * tokensPerEth;

  uint256 vendorBalance = yourToken.balanceOf(address(this));
  require(vendorBalance >= amountPurchased, "Not enough tokens left");

  // Sends Token to the buyer
  yourToken.transfer(msg.sender, amountPurchased);
  // Emits purchase to frontend 
  emit BuyTokens(buyer, amountOfETH, amountPurchased);
  return amountPurchased;
}
  
// withdraw function where onlyOwner can withdraw contract balance using transfer

function withdraw() public onlyOwner {
  // Check that contract is not empty 
  uint256 vendorBalance = yourToken.balanceOf(address(this));
  require(vendorBalance > 0, "Not enough ETH in contract");

  // Alternative Using call function instead of transfer 

  // (bool sent,) = msg.sender.call{value: address(this).balance}("");
  //  require(sent, "No Funds, Failed to withdraw");

  yourToken.transfer(msg.sender, vendorBalance);

}
  
  // sellToken function with event to emit for Frontend
  
  event SellTokens (address seller, uint256 amountETHtoReturn, uint256 _amountToSell);
  
  function sellTokens(uint256 _amountToSell) public {
    // Must try sell value greater than 0    
    require(_amountToSell > 0, "Amount must be greater than 0");

    uint256 amountETHtoReturn = _amountToSell / tokensPerEth;
    uint256 vendorBalanceETH = address(this).balance;

    // Make sure vendor ETH balance is higher than amount that needs to be returned

    require(vendorBalanceETH >= amountETHtoReturn, "Not enough ETH in contract");
       

    (bool sent) = yourToken.transferFrom(msg.sender, address(this), _amountToSell);
    require(sent, "Failed to Sell your token");

    (sent,) = msg.sender.call{value: amountETHtoReturn}("");
    require(sent, "Failed to return ETH");

    emit SellTokens(msg.sender, amountETHtoReturn, _amountToSell);

  }
}
