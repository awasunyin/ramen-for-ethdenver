pragma solidity ^0.4.17; 

import "./Bowls.sol";
import "./OpenZeppelin/SafeMath.sol";
import "./OpenZeppelin/ERC721.sol";

// TODO: Make it fully ERC721 compliant
// TODO: Add interfaces to other ERC721 tokens as tributes (specified at the end)


contract RamenYa is PreparedBowls {

    string public constant name = "Ramen";  
    string public constant symbol = "RAMEN";

    event DingRamenReady(uint256 _ramenId, uint16 _umamiLevel);

    struct Ramen {
        uint256 ramenId;
        uint16 umamiLevel;
        bool wasDelivered;
        bool wasConsumed;
    }

    mapping (uint => address) public ramenToOwner;
    mapping (address => uint) public ownerRamenCount;

    // plural of ramen is ramen
    Ramen[] public ramen;

    // ramen are only complete when there is at least one topping added
    function _addTopping(
        Bowl storage _bowlId, 
        Ingredient storage _topping, 
        Ingredient storage _noodles, 
        Ingredient storage _broth
        ) private onlyOwner 
        {
        if (_addingToppingPermitted(_bowlId, _topping.ingredientSKU, _topping.ingredientType) == true) {
            uint256 randamen = uint256(keccak256(_bowlId, _topping.ingredientSKU));
            uint16 umamiLevel = _calculateUmamiLevel(
                _bowlId.bowlId, 
                _topping.ingredientSKU,
                _topping.ingredientFlavorDepth,
                _topping.ingredientSeason,
                _noodles.ingredientFlavorDepth, 
                _noodles.ingredientSeason,
                _broth.ingredientFlavorDepth,
                _broth.ingredientSeason);
            uint256 ramenId = ramen.push(Ramen(randamen, umamiLevel, false, false)) - 1;
            ramenToOwner[ramenId] = msg.sender;
            ownerRamenCount[msg.sender]++;
            DingRamenReady(ramenId, umamiLevel);
        }
    }

    function _addingToppingPermitted(Bowl storage _bowlId, uint256 _ingredientSKU, uint16 _ingredientType) private view returns(bool) {
        // check that the ingredient is owned by this address
        if (_ingredientIsOwnedByCaller(_ingredientSKU) == true && _ingredientType == 3 && _bowlId.isBowlUsed == false) {
            return true;
        } else {
            return false;
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
        private view returns(uint16) 
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
    function _calculateBonumami(uint16 _ingredientFlavourDepth, uint16 _ingredirentSeason) private view returns(uint16) {
        if (whatSeasonIsIt() == _ingredirentSeason) {
            // TODO: use SafeMath (could not use mul here due to access issues)
            uint16 bonUmami = uint16(_ingredientFlavourDepth * 2);
            return bonUmami;
        } else {
            return _ingredientFlavourDepth;
        }
    }

    // transfers ramen
    function _deliverRamen(address _newOwner, Ramen storage _ramenId) private onlyOwner {
        require(_newOwner != address(0));
        require(_ramenId.wasDelivered == false);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        // once delivered it can only be consumed
        _ramenId.wasDelivered = true;
    }

    // you can only consume ramen that you bought
    function _itadakimasu(Ramen storage _ramenId) private onlyOwner {
        require(_ramenId.wasConsumed == false);
        extractIngredientsFromRamen(_ramenId);
    }

    function extractIngredientsFromRamen(Ramen storage _id) private {
        uint256 randSKU = uint256(keccak256(_id.ramenId));
        // change the generation of these are dependant on one variable only!
        // TODO: ingrediennt qualities will be influenced by 
        // the umami level of ramen
        uint16 randType = _ingredientIsWhatType(randSKU);
        uint16 randFlavourDepth = _ingredientIsWhatFlavourDepth(randSKU);
        uint16 randSeason = _ingredientIsWhatSeason(randSKU);
        uint256 id = ingredients.push(Ingredient(randSKU, randType, randFlavourDepth, randSeason, false)) - 1;
        // assign this new ingredient to owner
        ingredientToOwner[id] = msg.sender;
        ownerIngredientCount[msg.sender]++;
        IngredientForSale(id, randSKU);
    }

    // TODO: tribute to Cryptokitties, kitties get discounts
    function _feedRamenToCryptoKitty() private onlyOwner {

    }

    // TODO: tribute to CryptoZombies, zombies get discounts
    function _feedRamenToZombies() private onlyOwner {

    }

    // TODO: tribute to Blockgeeks, devs get discounts
    function _feedRamentoBlockgeeks() private onlyOwner {

    }
}