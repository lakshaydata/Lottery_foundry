//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import{Script,console} from "../lib/forge-std/src/Script.sol";
import{HelperConfig} from "./HelperConfig.s.sol";
import{VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import{LinkToken} from "../test/mocks/LinkToken.sol";
import{DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

//we are doing all this stuff only to create the subscription because without subscription you can not access VRFcoordinator;

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint64/**subscriptionid */) {
        HelperConfig helperConfig = new HelperConfig();//we called it to get the vrfcoordinator;
        (,  ,  ,  ,  ,  address vrfCoordinator,) = helperConfig.activeNetworkConfig();

        return createSubscription(vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns (uint64){
        console.log("Creating subscription on chain id :",block.chainid);
        vm.startBroadcast();
       uint64  subId = VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subId:",subId);
        console.log("Please update subscriptionId in HelperConfig.s.sol");
        return subId;
    }

    function run() external returns (uint64) {
        return createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script {
  uint96 public constant FUND_AMOUNT = 3 ether;
  //for funding we need subscriptionId,VRFCoordinator,Link
  function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (uint64 subId,  ,  ,  ,  ,  address vrfCoordinator, address link) = helperConfig.activeNetworkConfig();
        //helperCOnfig does not have link token,getting link token for sepolia from chainlink.docs;
        fundSubscription(vrfCoordinator, subId, link);
  }
  
  function fundSubscription(address vrfCoordinator,uint64 subId, address link) public {
    console.log("Funding subscription:", subId);
    console.log("Using vrfCoordinator:", vrfCoordinator);
    console.log(" On ChainId:", block.chainid);
    if(block.chainid == 11155111) {//yeh chain id hai kiski
      vm.startBroadcast();
      VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subId,FUND_AMOUNT);
      vm.stopBroadcast();
    }
    else {
      vm.startBroadcast();
      LinkToken(link).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subId));

      vm.stopBroadcast();
    }
  }

  function run() external {
    fundSubscriptionUsingConfig();
  }
}

contract AddConsumer is Script {

   function add_Consumer(address raffle, address vrfCoordinator, uint64 subId ) public {
    vm.startBroadcast();
    VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subId, raffle);
    vm.stopBroadcast();
   }
 
   function addConsumerUsingConfig(address raffle) public{
    HelperConfig helperConfig = new HelperConfig();
    (uint64 subId,  ,  ,  ,  ,  address vrfCoordinator, ) = helperConfig.activeNetworkConfig();
    add_Consumer(raffle, vrfCoordinator, subId);
  }
  function run() external {
    address raffle = DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
    addConsumerUsingConfig(raffle);
  }
}