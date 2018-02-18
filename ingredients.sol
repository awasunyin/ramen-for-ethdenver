pragma solidity ^0.4.17;

//import "./SafeMath.sol";
// import "./ERC721.sol";

contract IngredientMarketplace {

    // does it need to be a state variable?
    // storage or memory?
    uint256 ingredientIdLength = 12;
    uint256 ingredientIdModulus = 10 ** ingredientIdLength;
    uint256 ingredientCharacteristicModulus = 2;
    uint256 ingredientCharacteristicsModulus = 10 ** ingredientCharacteristicModulus;

    // event when a new ingredient is harvested
    event IngredientForSale(uint256 _sku, uint256 _ingredientSKU, string _ingredientName);
    event DingBowlReady(uint256 _ingredient1, uint256 _ingredient2, uint256 _cookingSessionId, uint256 _id);

    // ingredients have one unique id
    struct Ingredient {
        // unique stock keeping unit
        uint256 ingredientSKU;
        string ingredientName;
        uint16 ingredientType;
        uint16 ingredientFlavorDepth;
        uint16 ingredientSeason;
    }

    struct Bowl {
        uint256 ingredient1SKU;
        uint256 ingredient2SKU;
        // the id of the cooking session
        uint256 cookingSessionId; 
        // remember to add a cooldown feature
    }

    // list all the ingredients available
    Ingredient[] public ingredients;

    // list all the bowls available
    Bowl[] public bowls;

    // 
    function _generateRandomCharacteristic(uint _sku) private view returns (uint) {
        uint rand = uint(keccak256(_sku, block.number, block.difficulty));
        return rand % ingredientCharacteristicModulus;
    }
    
    function _harvestIngredient(uint256 _ingredientSKU, string _ingredientName, uint16 _ingredientType, uint16 _ingredientFlavorDepth, uint16 _ingredientSeason) private {
        uint256 sku = ingredients.push(Ingredient(_ingredientSKU, _ingredientName, _ingredientType, _ingredientFlavorDepth, _ingredientSeason)) - 1;
        IngredientForSale(sku, _ingredientSKU, _ingredientName);
    }

    function _generateRandomId(string _str) private view returns (uint) {
        uint256 rand = uint256(keccak256(_str, block.number, block.difficulty));
        return rand % ingredientIdModulus;
    }

    function _farmRandomIngredient(string _name) public {
        // change this
        uint256 randSKU = _generateRandomId(_name);
        uint16 randType = _ingredientIsWhatType(randSKU);
        uint16 randFlavourDepth = _ingredientIsWhatFlavourDepth(randSKU);
        uint16 randSeason = _ingredientIsWhatSeason(randSKU);
        _harvestIngredient(randSKU, _name, randType, randFlavourDepth, randSeason);
    }

    function _prepareBowl(uint256 _ingredient1, uint16 _ingredient1Type,  uint256 _ingredient2, uint16 _ingredient2Type) internal returns(uint) {
        require(_isCookingPermitted(_ingredient1, _ingredient1Type, _ingredient2, _ingredient2Type) == true);
        uint256 cookingSessionId = uint256(keccak256(_ingredient1, _ingredient2));
        // prepare the bowl
        uint256 bowlId = bowls.push(Bowl(_ingredient1, _ingredient2, cookingSessionId)) - 1;
        DingBowlReady(_ingredient1, _ingredient2, cookingSessionId, bowlId);
    }

    function _isCookingPermitted(uint _ingredient1, uint _ingredient1Type, uint _ingredient2, uint _ingredient2Type) internal pure returns (bool) {
        // you cannot an ingredient with itself!
        require(_ingredient1 != _ingredient2);

        // only noodles and broth can be cooked
        require(_ingredient1Type != 3 && _ingredient2Type != 3);
        
        // if the first ingredient is noodle, then 2 has to be broth
        if (_ingredient1Type == 1) {
            require(_ingredient2Type == 2);
            return true;
        } 
        // viceversa
        if (_ingredient1Type == 2) {
            require(_ingredient2Type == 1);
            return true;
        } else {
            return false;
        }
    }

    function _ingredientIsWhatType(uint _ingredientSKU) private view returns(uint16) {
        uint16 ingredientType = uint16(_generateRandomCharacteristic(_ingredientSKU));
        
        if (ingredientType <= 34) {
            return 1;
        }
        if (ingredientType <= 77) {
            return 2;
        } else {
            return 3;
        }
    }

    function _ingredientIsWhatFlavourDepth(uint _ingredientSKU) private view returns(uint16) {
        uint16 ingredientFlavourDepth = uint16(_generateRandomCharacteristic(_ingredientSKU));
        
        if (ingredientFlavourDepth <= 69) {
            return 1;
        }
        if (ingredientFlavourDepth <= 94) {
            return 2;
        } 
        
        if (ingredientFlavourDepth <= 97) {
            return 3; 
        } else {
            return 4;
        }
    }

     function _ingredientIsWhatSeason(uint _ingredientSKU) private view returns(uint16) {
        uint16 ingredientSeason = uint16(_generateRandomCharacteristic(_ingredientSKU));
        // spring
        if (ingredientSeason <= 25) {
            return 1;
        }
        // summer
        if (ingredientSeason <= 50) {
            return 2;
        } 
        // autumn
        if (ingredientSeason <= 75) {
            return 3;
        // winter
        } else {
            return 4;
        }
    }
}