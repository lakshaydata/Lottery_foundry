//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/deployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {
//we have to redefine event that we want to test in our test script;
    event EnteredRaffle(address indexed player);

  Raffle raffle;
  HelperConfig helperConfig;
  uint64 subscriptionId;
  bytes32 gasLane; //key hash
  uint256 interval;
  uint256 entrancefee;
  uint32 callbackGasLimit;
  address vrfCoordinator;
  address link;
  address public PLAYER = makeAddr("player");
  uint256 public constant STARTING_USER_BALANCE = 10 ether;


    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
       (raffle, helperConfig) = deployer.run();
         vm.deal(PLAYER, STARTING_USER_BALANCE);
        (
         subscriptionId,
         gasLane, //key hash
         interval,
         entrancefee,
         callbackGasLimit,
         vrfCoordinator,
         link
        ) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
      
    }
   
    function testRaffleInitialzesInOpenState() public view {
       
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    ///////////////////////////////////////////////
    //   enterRaffleTest   //
    function testEnterRaffle() public payable   {
        //assert(msg.value >=entrancefee && raffle.getRaffleState() == Raffle.RaffleState.OPEN );
       
        //Arrange
        vm.prank(PLAYER);//it wil make msg.sender as PLAYER
      //  vm.deal(PLAYER, entrancefee);yeh use karne ke baad toh revert nhin karna chhaiye but kar rha hai pta nhin kyun
        //Act and Assert
        vm.expectRevert(Raffle.Raffle_NotEnoughEthSent.selector);//in brackets we have written the error we are expecting;why we have used .selector here will be discussed later;
        raffle.enterRaffle();
    }

    function testRaffleRecordPlayerWhenTheyEnter() public payable {
        //Arrange
        vm.prank(PLAYER);
      //  vm.deal(PLAYER , 10 ether);  yeh pta nhin k kyun nhin chal rha 
        raffle.enterRaffle{value: entrancefee}();
        address playerRecorded = raffle.getplayer(0);
        assert(playerRecorded == PLAYER);
    }


    ////////////////////////////////////////////
   // Testing Events in foundry
    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));//lastly this is he address of the contract while deploying which you are expecting event
       //jitne indexed parameter aane hai shayad utne true kardo;
       
        //the below line is the emit which i expect to occur
        emit EnteredRaffle(PLAYER);
        // the below  line is the line which tell that while calling the enterRaffle function this emit will occur.
        raffle.enterRaffle{value: entrancefee}();

    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
     
       
       vm.warp(block.timestamp + interval + 1);//so that checkupkeep function can return true to call performupkeep
       vm.roll(block.number + 1);//yeh aise he likha hai koi kaam nhin hai abhi
       raffle.performUpkeep("");
       vm.expectRevert(Raffle.Raffle_NotOpen.selector);

       vm.prank(PLAYER);
       raffle.enterRaffle{value: entrancefee}();
    }

    function testCheckUpKeepReturnsFalseIfNotEnoughBalance() public {
      // vm.prank(PLAYER);
       vm.warp(block.timestamp + interval + 1);
       vm.roll(block.number + 1);
      // vm.deal(PLAYER, 0 ether);
       (bool upkeepneeded,) = raffle.checkUpkeep("");
        assert(upkeepneeded == false);

    }

    function testCheckUpKeepReturnsFalseIfNotOpen() public {
      //to make it calculating we have to ebetr the raffle therefore using vm.prank;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entrancefee}();
       vm.warp(block.timestamp + interval + 1);
       vm.roll(block.number + 1);
       vm.deal(PLAYER, 10 ether);

      raffle.performUpkeep("");
       (bool upkeepneeded,) = raffle.checkUpkeep("");
        assert(upkeepneeded == false);
    }

    //testCheckUpKeepReturnsFalseIfEnoughTimeHasNotPassed()
    //testCheckUpKeepReturnsTrueWhenAllAreGood()


    function testPerformUpkeepUpadatesRaffleState() public {
    vm.prank(PLAYER);
    vm.deal(PLAYER, entrancefee);
    raffle.enterRaffle{value: entrancefee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
  
    Raffle.RaffleState rState = raffle.getRaffleState();  //this is how we use enum outside
    assert(uint256(rState) == 1);

    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public {
   vm.prank(PLAYER);
    vm.deal(PLAYER, entrancefee);
    raffle.enterRaffle{value: entrancefee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    vm.expectRevert("non-existent request");
    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
      0,address(raffle)
    );//it should revert because we do not passed the valid request id to fulfillRandomWords function;
    }

    function testFulfilRandomWordsPicksAWinnerResetsAndSendsMoney() public {
      vm.prank(PLAYER);
    vm.deal(PLAYER, entrancefee);
    raffle.enterRaffle{value: entrancefee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);

    uint256 additionalEntrants = 5;
    uint256 startingIndex = 1;
    for(uint256 i= startingIndex; i<startingIndex; i++){
      address player = address(uint160(i));
      hoax(player, STARTING_USER_BALANCE);
      raffle.enterRaffle{value: entrancefee}();
    }

    //random no. can only be called by vrfcoordinator so we have to pretend like chainlink vrf to get random number and pick winner

    //but how to get the requestId
    vm.recordLogs();
    raffle.performUpkeep("");
     Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];
    //this will give you the request Id;

    VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
      uint256(requestId),address(raffle)
    );
    //we have to test that finally the rafflestate in open and the winner address is not 0 there shoul be some winner
      assert(uint256(raffle.getRaffleState()) == 0);
      assert(address(raffle.getrecentWinner()) != address(0));
      assert(raffle.getLengthOfPlayers() == 0);

      uint256 previousTimeStamp = raffle.getLastTimeStamp();
      assert(previousTimeStamp < raffle.getLastTimeStamp());

      uint256 prize = (additionalEntrants + 1)*(STARTING_USER_BALANCE);
      assert(raffle.getrecentWinner().balance == STARTING_USER_BALANCE + prize - entrancefee);//because entrance fee jitn epaise toh uske priz emein he jud gaye na because utne paise toh uske account se pehle he deduct ho rakhe hain.
    }
}

