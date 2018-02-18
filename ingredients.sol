pragma solidity ^0.4.17;

//import ".OpenZeppelin/SafeMath.sol";
// import ".OpenZeppelin/ERC721.sol";
import "./OpenZeppelin/Ownable.sol";


contract IngredientMarketplace is Ownable {

    // does it need to be a state variable?
    // storage or memory?
    uint256 ingredientIdLength = 12;
    uint256 ingredientIdModulus = 10 ** ingredientIdLength;
    uint256 ingredientCharacteristicLength = 2;
    uint256 ingredientCharacteristicsModulus = 10 ** ingredientCharacteristicLength;

    // event when a new ingredient is harvested
    event IngredientForSale(uint256 _sku, uint256 _ingredientSKU, string _ingredientName);
    event BurnedIngredient(uint _sku, address _owner);

    // ingredients have one unique id
    struct Ingredient {
        // unique stock keeping unit
        uint256 ingredientSKU;
        string ingredientName;
        uint16 ingredientType;
        uint16 ingredientFlavorDepth;
        uint16 ingredientSeason;
    }

    // list all the ingredients available
    Ingredient[] public ingredients;

    // mappings
    mapping (uint => address) public ingredientToOwner;
    mapping (address => uint) ownerIngredientCount;

    // NOTE: keccak256 costs 30 gas + 6 gas (per word)
    function _generateRandomCharacteristic(uint _sku) private view returns (uint) {
        uint rand = uint(keccak256(_sku, block.number, block.difficulty));
        return rand % ingredientCharacteristicsModulus;
    }
    
    function _harvestIngredient(uint256 _ingredientSKU, string _ingredientName, uint16 _ingredientType, uint16 _ingredientFlavorDepth, uint16 _ingredientSeason) private {
        uint256 id = ingredients.push(Ingredient(_ingredientSKU, _ingredientName, _ingredientType, _ingredientFlavorDepth, _ingredientSeason)) - 1;
        ingredientToOwner[id] = msg.sender;
        ownerIngredientCount[msg.sender]++;
        IngredientForSale(id, _ingredientSKU, _ingredientName);
    }

    // TODO: Find a better source of randomness
    // Note: Both the timestamp and the block hash can be influenced by miners
    // to some degree. Bad actors in the mining community can for example run a 
    // casino payout function on a chosen hash and just retry a different hash 
    // if they did not receive any money.
    function _generateRandomId(string _str) private view returns (uint) {
        uint256 rand = uint256(keccak256(_str, block.number, block.difficulty));
        return rand % ingredientIdModulus;
    }

    function _farmRandomIngredient(string _name) public {
        uint256 randSKU = _generateRandomId(_name);
        // change the generation of these are dependant on one variable only!
        uint16 randType = _ingredientIsWhatType(randSKU);
        uint16 randFlavourDepth = _ingredientIsWhatFlavourDepth(randSKU);
        uint16 randSeason = _ingredientIsWhatSeason(randSKU);
        _harvestIngredient(randSKU, _name, randType, randFlavourDepth, randSeason);
    }

    function _ingredientIsWhatType(uint _ingredientSKU) private view returns(uint16) {
        uint16 ingredientType = uint16(_generateRandomCharacteristic(_ingredientSKU));
        
        // noodles
        if (ingredientType <= 34) {
            return 1;
        }
        // broth
        if (ingredientType <= 77) {
            return 2;
        // topping
        } else {
            return 3;
        }
    }

    function _ingredientIsWhatFlavourDepth(uint _ingredientSKU) private view returns(uint16) {
        uint16 ingredientFlavourDepth = uint16(_generateRandomCharacteristic(_ingredientSKU));
        
        // common flavour depth 
        if (ingredientFlavourDepth <= 69) {
            return 1;
        }
        // semi rare flavour depth 
        if (ingredientFlavourDepth <= 94) {
            return 2;
        } 
        // rare flavour depth
        if (ingredientFlavourDepth <= 97) {
            return 3; 
        
        // mythical flavour depth
        } else {
            return 4;
        }
    }

     // TODO: season is not fully used in this implementation
     // for the future, ingredient generation might come with bonuses or special
     // characteristics depending on the season: e.g. veggies have higher flavour
     // when issued in autumn or meat has more flavour when issued in winter.
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

    function _ingredientIsOwnedByCaller(uint256 _ingredientSKU) internal view returns(bool) {
        if (ingredientToOwner[_ingredientSKU] == msg.sender) {
            return true;
        } else {
            return false;
        }
    }

    // only considering 2018 for now
    function whatSeasonIsIt() internal view returns(uint16) {
        uint256 timestamp = block.timestamp;
        // until march 20 2018
        if (timestamp < 1521504001) {
            return 4;
        }

        // until june 21 2018
        if (timestamp < 1529539201) {
            return 1;
        }

        // until september 22 2017
        if (timestamp < 1537574401) {
            return 2;
        }

        // until december 21 2018
        if (timestamp < 1545350401) {
            return 3;
        
        // anything later, innacurate, but temporary
        } else {
            return 4;
        }
    }
    // TODO: Ingredients Generation
    // TODO: Ingredients Auction
}