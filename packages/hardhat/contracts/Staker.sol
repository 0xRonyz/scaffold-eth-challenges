// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;

  event Stake(address, uint256);


  function stake() public payable deadlineNotMet {
    
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }



  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  uint256 public deadline = block.timestamp + 72 hours;


  // Both of these can be combined to bool.

  modifier deadlineNotMet() {
    require (block.timestamp < deadline, "Deadline has passed");
    _;
  }
  modifier deadlineMet() {
    require (block.timestamp > deadline, "Deadline not met");
    _;
  }

  bool public exStatus;

  // Only allows one execute to run while status is false, once it runs succesfully it changes status to TRUE and you can't run execute again. 

  modifier executeStatus() {
    require (exStatus == false, "Execute has been completed");
    _;
  }


  function execute() public deadlineMet executeStatus {
    uint256 contractTotal = address(this).balance;
    if (contractTotal >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      exStatus = true; 
    }
  }     

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  modifier thresholdNotMet() {
    require (address(this).balance < threshold, "Threshold was met");
    _;
  }
      

  // Add a `withdraw()` function to let users withdraw their balance

  function withdraw() public thresholdNotMet deadlineMet payable {
      require(balances[msg.sender] > 0, "Not enough funds");
      uint256 userBalance = balances[msg.sender];
      balances[msg.sender] = 0;
      (bool sent, ) = msg.sender.call{value: userBalance}("");
      require(sent, "Failed to send");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  event TimeLeft(uint256);
  
  function timeLeft() public view returns (uint256) {
    if (block.timestamp < deadline) {
      // uint256 leftTime = (deadline - block.timestamp);
      return deadline - block.timestamp;
    } else if (block.timestamp > deadline) {
      return 0;
    }
    
  }

  // Add the `receive()` special function that receives eth and calls stake()

  receive() external payable {
      stake();
  }

}


