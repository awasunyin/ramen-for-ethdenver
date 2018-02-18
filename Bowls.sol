pragma solidity ^0.4.17;

import "./OpenZeppelin/BasicToken.sol";
import "./Ingredients.sol";

// TODO: Make it fully ERC721 compliant

contract PreparedBowls is IngredientMarketplace {

    string public constant name = "Bowls";  
    string public constant symbol = "BOWL";

    uint lastUpdated;
    // it takes 30 minutes to cook the bowl
    uint cookingTimePerBowl = 30 minutes;

    // ding! the bowl is ready for the topping!
    event DingBowlReady(uint256 _ingredient1, uint256 _ingredient2, uint256 _cookingSessionId, uint256 _id);
    
    // a bowl has been destroyed T_T
    event BurnedBowl(uint _bowlToOwnerIndex, address _owner);

    struct Bowl {
        // noodles
        uint256 ingredient1SKU;
        // broth
        uint256 ingredient2SKU;
        // the id of the cooking session
        uint256 bowlId; 
        // remember to add a cooldown feature
        uint32 cookingReadyTime;
        // was this bowl already used
        bool isBowlUsed;
    }

    // list all the bowls available
    Bowl[] public bowls;

    // mapping
    mapping (uint => address) public bowlToOwner;
    mapping (address => uint) public ownerBowlCount;

    // update with all functions
    function _prepareBowl(Ingredient storage _ingredient1, Ingredient storage _ingredient2) internal onlyOwner returns(uint) {
        require(_isCookingPermitted(_ingredient1.ingredientSKU, _ingredient1.ingredientType, _ingredient2.ingredientSKU, _ingredient2.ingredientType) == true);
        uint256 cookingSessionId = uint256(keccak256(_ingredient1, _ingredient2));
        // prepare the bowl
        // Note: Cooking session id is not used
        uint256 bowlId = bowls.push(Bowl(_ingredient1.ingredientSKU, _ingredient2.ingredientSKU, cookingSessionId, uint32(now + cookingTimePerBowl), false)) - 1;
        bowlToOwner[bowlId] = msg.sender;
        ownerBowlCount[msg.sender]++;
        DingBowlReady(_ingredient1.ingredientSKU, _ingredient2.ingredientSKU, cookingSessionId, bowlId);
        // change ingredientUsed to true
        _ingredientIsUsed(_ingredient1);
        _ingredientIsUsed(_ingredient2);
   
    }

    function _ingredientIsUsed(Ingredient storage _ingredientSKU) private {
        _ingredientSKU.ingredientUsed = true;
    }

   function _isCookingPermitted(Ingredient storage _ingredient1, Ingredient storage _ingredient2) internal view returns (bool) {
        // the ingredients can only be used once!
        require(_ingredient1.ingredientUsed == false && _ingredient2.ingredientUsed == false);
        
        // you cannot an ingredient with itself!
        require(_ingredient1.ingredientSKU != _ingredient2.ingredientSKU);

        // only noodles and broth can be cooked
        require(_ingredient1.ingredientType != 3 && _ingredient2.ingredientType != 3);
        
        // if the first ingredient is noodle, then 2 has to be broth
        if (_ingredient1.ingredientType == 1) {
            require(_ingredient2.ingredientType == 2);
            return true;
        } 
        // viceversa
        if (_ingredient1.ingredientType == 2) {
            require(_ingredient2.ingredientType == 1);
            return true;
        } else {
            return false;
        }
    }

    function updateTimestamp() public {
        lastUpdated = now;
    }

    function kitchenTimer() public view returns (bool) {
        return (now >= (lastUpdated + 30 minutes));
    }

     function _startCookingTime(Bowl storage _bowlId) private {
        _bowlId.cookingReadyTime = uint32(now + cookingTimePerBowl);
    }

    function _isReady(Bowl storage _bowlId) internal view returns (bool) {
        return (_bowlId.cookingReadyTime <= now);
    }

    function _transferOwnership(address _newOwner, Bowl storage _bowlId) private onlyOwner {
        require(_newOwner != address(0));
        require(_isReady(_bowlId) == true);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // UNUSED
    // to burn ingredients once they're used for cooking
    function burnIngredient(uint256 _ingredientSKU) internal onlyOwner {
        // check that the owner actually has this ingredient!
        require(ingredientToOwner[_ingredientSKU] == msg.sender);
        delete ingredientToOwner[_ingredientSKU];
        BurnedIngredient(_ingredientSKU, msg.sender);
    }
    
    // UNUSED
    // Note: Is it necessary to burn?
    // to burn the bowl once it has transfered
    function burnBowl(uint256 _bowlToOwnerId) private onlyOwner {
        require(bowlToOwner[_bowlToOwnerId] == msg.sender);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        delete bowlToOwner[_bowlToOwnerId];
        BurnedBowl(_bowlToOwnerId, msg.sender);
    }
}