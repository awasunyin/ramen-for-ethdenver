pragma solidity ^0.4.17;

import "./OpenZeppelin/BasicToken.sol";
import "./Ingredients.sol";


contract PreparedBowls is IngredientMarketplace {

    uint lastUpdated;
    uint cookingTimePerBowl = 30 minutes;

    event DingBowlReady(uint256 _ingredient1, uint256 _ingredient2, uint256 _cookingSessionId, uint256 _id);
    event BurnedBowl(uint _bowlToOwnerIndex, address _owner);

    struct Bowl {
        uint256 ingredient1SKU;
        uint256 ingredient2SKU;
        // the id of the cooking session
        uint256 bowlId; 
        // remember to add a cooldown feature
        uint32 cookingReadyTime;
    }

    // list all the bowls available
    Bowl[] public bowls;

    // mapping
    mapping (uint => address) public bowlToOwner;
    mapping (address => uint) public ownerBowlCount;

    // update with all functions
    function _prepareBowl(uint256 _ingredient1, uint16 _ingredient1Type,  uint256 _ingredient2, uint16 _ingredient2Type) internal onlyOwner returns(uint) {
        require(_isCookingPermitted(_ingredient1, _ingredient1Type, _ingredient2, _ingredient2Type) == true);
        uint256 cookingSessionId = uint256(keccak256(_ingredient1, _ingredient2));
        // prepare the bowl
        uint256 bowlId = bowls.push(Bowl(_ingredient1, _ingredient2, cookingSessionId, uint32(now + cookingTimePerBowl))) - 1;
        bowlToOwner[bowlId] = msg.sender;
        ownerBowlCount[msg.sender]++;
        DingBowlReady(_ingredient1, _ingredient2, cookingSessionId, bowlId);
        // burn the ingredients
        burnIngredient(_ingredient1);
        burnIngredient(_ingredient2);
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

    // to burn ingredients once they're used for cooking
    function burnIngredient(uint256 _ingredientSKU) internal onlyOwner {
        // check that the owner actually has this ingredient!
        require(ingredientToOwner[_ingredientSKU] == msg.sender);
        delete ingredientToOwner[_ingredientSKU];
        BurnedIngredient(_ingredientSKU, msg.sender);
    }

    // to burn the bowl once it has transfered
    function burnBowl(uint256 _bowlToOwnerId) private onlyOwner {
        require(bowlToOwner[_bowlToOwnerId] == msg.sender);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure
        delete bowlToOwner[_bowlToOwnerId];
        BurnedBowl(_bowlToOwnerId, msg.sender);
    }

}