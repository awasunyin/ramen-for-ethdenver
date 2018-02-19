# RamenYa.world 

The temporary static homepage and its theme for this project was generated with jekyll and an open-sourced theme, apologies for the noisy files in the master branch. (シ_ _)シ

*Status: Initial Prototype.*
Ramen-Ya (from Japanese, _Ramen Shop_) is a collaborative platform for collectibles. A grosso modo, it is composed by an ecosystem of ERC721 style tokens (AKA: non fungible tokens). Ramen is a great source of energy that you might need
after playing with CryptoKitties or just all the calories that you might burn while you try to trading with crypto using exchanges or simply because you're a developer and you need to feed yourself time to time. Here are some inspiring quotes displaying that ramen is a true source of wisdom:
> The only men I need is Ramen. - Anonymous
>
> Ramen is a dish that's very high in calories and sodium. One way to make it slightly healthier is to leave the soup and just eat the noodles. – Masaharu Morimoto

## Introduction to RamenYa's System
Unlike other ERC721 collectibles, in Ramen-Ya not all the collectibles are immediately transferable: it will only be possible to sell or consume once a "Ramen" bowl (noodles + soup + topping) has been cooked. Bowls (noodles + soup) can be transferred, but as Bowls do not profit from the potential level of umami (from Japanese, level of savoriness) the value of it is limited. Ingredients cannot be transferred, they can only be combined to form Bowls.

## Design of RamenYa
Even though a production-ready contract would be monolithic, for readability purposes, this project includes all the contracts in a modular way.
* Ingredients.sol
* Bowls.sol
* Ramen.sol
* RamenCoin.sol (not implemented)
* OpenZeppelin/* (contracts)
```
Ramen <--inherits--  Bowls <--inherits-- Ingredients <--inherits-- ERC721(OpZep) 
```

## RamenYa in Depth
Here are explained some particularities of this game's system.

### Ingredients
Initia ingredients in RamenYa come to existance when farmers from around to world havest them. This event depends on many factors, such as time, season, because it 
would not be sustainable otherwise and we would force farmers to opt unsustainable methods that would harm the planed unnecessarily. 

#### Ingredient characteristics
```
struct Ingredient {
        // unique stock keeping unit
        uint256 ingredientSKU;
        // noodles, broth, or topping
        uint16 ingredientType;
        uint16 ingredientFlavorDepth;
        uint16 ingredientSeason;
        bool ingredientUsed;
    }
```
The characteristics are determined in combination of a pseudrandomly generated 2-digits number and some hard coded ranges that determine the likelihood of each characteristic appearing. For example, if number is truly random, there's 69% of chance that it will have level 1 in Flavour Depth and 1% of likelihood for level 4.
```
    function _ingredientIsWhatFlavourDepth(uint _ingredientSKU) internal view returns(uint16) {
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
        if (ingredientFlavourDepth <= 99) {
            return 3; 
        
        // mythical flavour depth
        } else {
            return 4;
        }
    }
```
Ingredients cannot be directly transfered, they can only be combined to form Bowls (and only type noodles and broth can be combined at this stage). The properties of the ingredients used will influence in the final Ramen's umami.

### Bowls
Bowls are unique combinations of pairs of unique ingredients (where one must be noodles and the other one must be broth). Each bowl needs 30 minutes of preparation and they are transferrable. The only way of owning Bowls is either by combining ingredients yourself or by acquiring it at the Kitchen (where you can find all the bowls that are ready and check their properties). 

#### Bowls characteristics
```
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
```

### Ramen
Ramen are the combination of a unique Bowl and a unique ingredient (of type topping). The main rule here is that the bowl must have been acquired from the kitchen: another player has prepared the bowl for you. Once acquired, you can choose what topping to add and enjoy Ramen in its true form.

Note: for the sake of simplicity, Ramen in RamenYa are composed of 3 main ingredients (noodles, broth, topping), but in real life they should have [4 main components](http://www.pepper.ph/the-four-parts-of-a-ramen-bowl/) and unlimited toppings (to be implemented). 

#### Characteristics of a Ramen
```
struct Ramen {
        uint256 ramenId;
        uint16 umamiLevel;
        bool wasDelivered;
        bool wasConsumed;
    }
```
Where umami level is determined by the following function that considers the original ingredients characteristics and the current season (if an ingredient has season 1 (spring) and current date is within the spring dates, there's a x2 bonus):
```
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
```
Once Ramen has been formed, meaning that you bought a browl and added a topping, this unique ramen becomes transferrable. A buyer pays an amount of ETH or RamenCoin for your Ramen, which later on can be consumed. Once a ramen is consumed, there are two things that will happen: you'll feel the warmth in your stomach and a new ingredient will spawn from it, which later on you can use to play again. This new ingredient's properties will depend on the Ramen's umamiLevel:

```
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
```

As tribute to the producers of my learning content and (personal) continuous learning of smart contract development, there 
will be interfaces with existing ERC721 tokens. The idea is that, e.g., if ramen is delivered to Kitties, the Kitty will give you in return certain ingredients (freshly caught birds, fish, etc). And who knows, maybe if you feed the same kitty many times, the kitty wants to stay with you? (☆▽☆)

## Challenges & Future Main Design Changes
1. True randomness of keccak256
2. The total gas price of every contract
3. Check on probabilities, are those likelihoods actually correct?
4. Create RamenCoin, an ERC20 token, as one of the payment methods for participating in the game

## Credits
1. Website theme Moon: https://github.com/TaylanTatli/Moon
2. Images: Google Images 
