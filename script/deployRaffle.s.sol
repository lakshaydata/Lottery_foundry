//SPDX-License-Identifier:MIT

import {Script} from "../lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import{CreateSubscription, FundSubscription, AddConsumer} from "./interaction.s.sol";
pragma solidity ^0.8.18;

//iska kaam hai raffle contract deploy karke wapis bhejna;

contract DeployRaffle is Script {

    function run() external returns (Raffle, HelperConfig) {
      HelperConfig helperConfig = new HelperConfig();
      ( uint64 subscriptionId,
        bytes32 gasLane, //key hash
        uint256 interval,
        uint256 entrancefee,
        uint32 callbackGasLimit,
        address vrfCoordinator,
        address link) = helperConfig.activeNetworkConfig();
       
        //or   
        //NetworkConfig config = helperConfig.activeNetworkConfig();
       //all the above information depends on the chain we are using.which are stored in acivenetworkconfig;
       //By using this code snippet, the DeployRaffle contract retrieves the configuration parameters it needs for deploying and initializing the Raffle contract

      if (subscriptionId == 0){
        //we need a subscriptionId;
        CreateSubscription create_Subscription = new CreateSubscription();
        subscriptionId = create_Subscription.createSubscription(vrfCoordinator);
          }

      //fund it
      FundSubscription fundSubscription = new FundSubscription();
      fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, link);

        vm.startBroadcast();
        Raffle raffle = new Raffle(
        subscriptionId,
        gasLane,
        interval,
        entrancefee,
        callbackGasLimit,
        vrfCoordinator
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.add_Consumer(address(raffle), vrfCoordinator, subscriptionId);
        return (raffle, helperConfig);
    }

}














