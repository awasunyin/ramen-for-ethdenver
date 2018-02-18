pragma solidity ^0.4.17; 

import "./Bowls.sol";
import "./OpenZeppelin/SafeMath.sol";

contract RamenYa is PreparedBowls, SafeMath {

    struct Ramen {
        uint256 ramenId;
        uint256 toppingSKU;
        uint16 noodleFlavourDepthLevel;
        uint16 brothFlavourDepthLevel;
        uint16 umamiLevel;

    }

    // plural of ramen is ramen
    Ramen[] public ramen;

    //TODO: addTopping
    function _addTopping(uint256 _bowlId, uint256 _ingredientSKU) private onlyOwner {
        require(_addingToppingPermitted(_bowlId, _ingredientSKU) == true);

    }

    function _addingToppingPermitted(uint256 _bowlId, uint256 _ingredientSKU, uint16 _ingredientType) private {
        // check that the ingredient is owned by this address
        if (require(_ingredientIsOwnedByCaller(_ingredientSKU) == true) && _ingredientType == 3){
            return true;
        } else {
            false;
        }
    }

    function _calculateUmamiLevel(
        uint256 _bowlId, 
        uint256 _toppingSKU,
        uint16 _toppingFlavourDepth, 
        uint16 _toppingSeason,
        uint16 _noodlesFlavourDepth, 
        uint16 _noodlesSeason,
        uint16 _brothFlavourDepth,
        uint16 _brothSeason) 
        returns(uint16) 
        {
        uint randami = uint(keccak256(_bowlId, _toppingSKU)); 
        uint16 umami = uint16(randami % ingredientCharacteristicsModulus);
        uint16 bonusFromTopping = _calculateBonumami(_toppingFlavourDepth, _toppingSeason);
        uint16 bonusFromNoodles = _calculateBonumami(_noodlesFlavourDepth, _noodlesSeason);
        uint16 bonusFromBroth = _calculateBonumami(_brothFlavourDepth, _brothSeason);
        uint16 finami = umami + bonusFromTopping + bonusFromNoodles + bonusFromBroth;
        
        // TODO: Check the probabilities, but it should be exponentially
        // lower per unami level
        if (finami <= 75) {
            return 1;
        }
        if (finami <= 90) {
            return 2;
        }

        if (finami <= 100) {
            return 3;
        }
        // legendary level
        if (finami > 100) {
            return 4;
        }
    }

    // calculate the bonus umami that comes from ingredients
    function _calculateBonumami(uint16 _ingredientFlavourDepth, uint16 _ingredirentSeason) private returns(uint16) {
        if (whatSeasonIsIt == _ingredirentSeason) {
            uint16 bonUmami = mul(_ingredientFlavourDepth, 2);
            return bonUmami;
        } else {
            return _ingredientFlavourDepth;
        }
    }

    //TODO: consumeRamen




}