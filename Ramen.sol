pragma solidity ^0.4.17; 

import "./Bowls.sol";

contract RamenYa is PreparedBowls {

    struct Ramen {
        uint256 ramenId;

    }

    // plural of ramen is ramen
    Ramen[] public ramen;




}