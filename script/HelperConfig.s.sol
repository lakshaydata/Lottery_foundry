//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Script} from "../lib/forge-std/src/Script.sol";
import {VRFCoordinatorV2Mock} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    struct NetworkConfig{
        uint64 subscriptionId;
        bytes32 gasLane; //key hash
        uint256 interval;
        uint256 entrancefee;
        uint32 callbackGasLimit;
        address vrfCoordinator;
        address link;
    }
        NetworkConfig public activeNetworkConfig;

        constructor () {
                    if (block.chainid == 11155111){
                        activeNetworkConfig = getSepoliaEthConfig();
                    }
                    else {activeNetworkConfig = getAnvilEthConfig();}

                }


    function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
        return NetworkConfig({
            entrancefee: 0.01 ether,
            interval: 30, //in seconds by default
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,//from docs.chain.link vrf coordinaor
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,//from docs.chain.link vrf coordinaor
            subscriptionId:6234,//soon we will update it to our subId;
            callbackGasLimit: 500000 , //500000 gas !
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789  //from docs.chain.link vrf coordinaor
        
    });
    }
                
    function getAnvilEthConfig() public returns (NetworkConfig memory){
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;        //iska matlab pehle he wo kisi aur chain ka vrfcoordinator leke aaya hai;
        }
        uint96 baseFee = 0.25 ether; //0.25 LINK
        uint96 gasPriceLink = 1e9; //1gwei LINK
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee,gasPriceLink);
        LinkToken link = new LinkToken();  //we have imported the mock link token for anvil.
        vm.stopBroadcast();
          
        //when we call for random words from vrfcoordinator chainlink nodes take amount link tokens from our subscription Id as fees
        //baseFee is the flat fees.

        return NetworkConfig({
            entrancefee: 0.01 ether,
            interval: 30, //in seconds by default
            vrfCoordinator: address(vrfCoordinatorMock),
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            subscriptionId: 0,//our script will add this
            callbackGasLimit: 500000,  //500000 gas !
            link: address(link) //this will get you the link token for anvil chain
        });
    }
}