/**
 *Submitted for verification at Etherscan.io on 2019-02-05
*/

pragma solidity ^0.5.1;

contract RPSContract {
    
    address public gamer1_address; 
    address public gamer2_address;
    address public winner_address;
    
    uint8 private gamer1_action;
    uint8 private gamer2_action;
    uint8 private winner_num;
    
    uint8 constant ROCK = 1; // Камень 
    uint8 constant PAPER = 2; // Сержант наверно =)
    uint8 constant SCISSORS = 3; // Ножницы
    
    constructor() public {
       // constructor    
       reset();
    }

    function setDH() private // Ничья
    {
        winner_num = 3;
    }
    function setWinner1() private
    {
        winner_address = gamer1_address;
        winner_num = 1 ;
    }

    function setWinner2() private
    {
        winner_address = gamer2_address;
        winner_num = 2; 
    }
    
    function getResult() private
    {
        if (gamer1_action == gamer2_action) {
          setDH(); // Ничья
        }
        if ( (gamer1_action + 1) == gamer2_action ) {
            // 1 и 2 = Бумага накрывает Камень
            // 2 и 3 = Бумагу резуж Ножницы
            setWinner2();
        } 
        
        if ( (gamer1_action - 1) == gamer2_action ) {
            // 2 и 1 = Бумага накрывает Камень
            // 2 и 3 = Бумагу резуж Ножницы
            setWinner1();
        } 
        if ((gamer1_action -  gamer2_action) == 2) 
        {
            setDH();
        }
        
        if ((gamer2_action -  gamer1_action) == 2) 
        {
            setDH();
        }        
    }
    
    function play(uint8 val) public returns(uint8) {
        if(val > SCISSORS && val < ROCK) {
            return 0;  // Фигню прислали
        }
        
        if(gamer1_address == address(0))
        {
            gamer1_address = msg.sender;
            gamer1_action = val;
            return 1;
        }
        
        gamer2_address = msg.sender;
        gamer2_action = val;
        getResult();
        return 2;
    }
    
    function reset() private {
        gamer1_address = address(0);
        gamer2_address = address(0);
        winner_address = address(0);
        
        gamer1_action = 0;
        gamer2_action = 0;
        winner_num = 0;
    }
}
