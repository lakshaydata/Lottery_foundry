// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;
/////////////////////////////yeh dono jo import kiya hai unka kaam kya hai?
/////////////////////////////
import {VRFCoordinatorV2Interface} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//import {ConfirmedOwner} from "../lib/chainlink-brownie-contracts/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * @title A sample of Raffle Contract
 * @author Lakshay Data
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */

contract Raffle is VRFConsumerBaseV2 {
    uint256 private immutable i_entrancefee;
    address payable[] private s_players; //as it will be chainging with time as new players come so it cannot be immutable;
    //duration of the lottery in seconds....
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;  
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    /**events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint64 subscriptionId,
        bytes32 gasLane, //key hash
        uint256 interval,
        uint256 entrancefee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entrancefee = entrancefee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    error Raffle_NotEnoughEthSent();
    error Raffle_TransferFailed();
    error Raffle_NotOpen();
    error Raffle_UpkeepNotNeeded();
    /**type declarations (enum)*/
    enum RaffleState {
        OPEN, //0
        CALCULATING //1
        //CLOSED  2
    }

    function enterRaffle() external payable {
        //  require(msg.value >= i_entrancefee ,"Not Enough ETH sent.");
        //using custom error
        if (msg.value < i_entrancefee) {
            revert Raffle_NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_NotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    //1. get a random number
    //2. Use the random number to pick a player
    //3. Be automatically called

    //when is the winner suppposed to be picked ?
    /**
     *@dev This is the function that the Chainlink Automation nodes call to see if it's time to perform an upkeep ;
     * The following should be true for this to return true:
     * 1. The time interval has passed between raffle runs
     * 2. The raffle is in OPEN state
     * 3. The contract has the ETH(aka , players)
     * 4. (Implicit) the subscription is funded wih LINK.
     */

      
     //yeh ek set tareeka hai vrf ko use karne ka checkUpKeep and PerformUpKeep bnake;
    function checkUpkeep( bytes memory /* checkData */) public view returns (bool upkeepNeeded,
            bytes memory /* performData */ //perform data is anyother data needed to perform this upkeep ;
        )
    //upkeepneeded will be 1 when we want to call the random no.;right now we do not need perform Data
    {
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) < i_interval);
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPLayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPLayers);
        return (upkeepNeeded, "0*0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNotNeeded();
        }
        //check to see if enough time has passed.

        s_raffleState = RaffleState.CALCULATING;
        // to get a random number...
        //1. to request the RNG;

        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    

    //2. get the random number;
    function fulfillRandomWords(
        uint256 /*_requestId*/,
        uint256[] memory _randomWords
    ) internal override {
        //checks
        //effects (our own contract)
        uint256 indexOfwinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfwinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit PickedWinner(winner); //event ko interaction se pehle rakho because usmein app kisi se interaction thodi kar rahe ho.
        // Interactions (other contracts)
        //now how to transfer whole balance of this contract to the address of winner
        (bool success, ) = winner.call{value: address(this).balance}(" ");
        if (!success) {
            revert Raffle_TransferFailed();
        }
    }

    /**getter function for getting entrancefee */

    function getEntrancefee() external view returns (uint256) {
        return i_entrancefee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getplayer(uint256 index) external view returns(address){
        return s_players[index];
    }

    function getrecentWinner() external view returns(address){
        return s_recentWinner;
    }

     function getLengthOfPlayers() external view returns(uint256){
        return s_players.length;
    }

     function getLastTimeStamp() external view returns(uint256){
        return s_lastTimeStamp;
    }
}

