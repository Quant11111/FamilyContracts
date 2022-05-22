// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract TransacEscrow {

    //variables :
    address public factory ;
    address payable public buyer ;
    address payable public seller ; 
    address payable public admin ;
    bool[] public inProgress; //state of each milestones (inProgress = true / ended = false)
    uint[] public weiPrices ; //prices array (one price per milestone)
    uint weiPricesSum ;
    uint public transacId;
    uint userTaxes = 3; //fees in % if function called by user
    uint adminTaxes = 20; //fees in % if function called by admin

    //modifiers

    modifier checkIfFactory{
        require(msg.sender == factory);  //ensure that _msgSender isn't faked being feeled manualy while the function is called outside of the factory
        _;
    }

    constructor(uint _transacId, address payable _buyer, address payable _seller, address payable _admin, uint[] memory _weiPrices , uint _weiPricesSum) payable{
        require(msg.value >= _weiPricesSum );
        factory = msg.sender;        
        weiPrices = _weiPrices;
        buyer = _buyer ; 
        seller = _seller ; 
        admin = _admin ;
        transacId = _transacId;
        weiPricesSum = _weiPricesSum ; 
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            inProgress[i] = true; //init of the milestonesStateArray
        }
    }


    ////////////////////////////////////////////////////User Functions : ////////////////////////////////////////////////////////

    //the buyer unlock all remaining milestones
    function unlockAll(address _msgSender) external checkIfFactory {
        require(_msgSender == buyer);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                unlockMilestoneInternal(i, userTaxes);
            }
        }
    } 

    //the seller refound all remaining milestones
    function refoundAll(address _msgSender) external checkIfFactory {
        require(_msgSender == seller);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                refoundMilestoneInternal(i, userTaxes);
            }
        }
    } 

    //the buyer unlock the payment number "_index"  !! 1rst milestone index = 0
    function unlockMilestone(uint _index, address _msgSender) public checkIfFactory{
        require(_msgSender == buyer);
        unlockMilestoneInternal(_index, userTaxes);
    }

    //the seller refound the payment number "_index"  !! 1rst milestone index = 0
    function refoundMilestone(uint _index, address _msgSender) public checkIfFactory{
        require(_msgSender == seller);
        refoundMilestoneInternal(_index, userTaxes);
    }


    ///////////////////////////Admin Functions : //////////////////////////////////

    //the admin unlock all remaining milestones
    function unlockAllAdmin() external checkIfFactory {
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                unlockMilestoneInternal(i, adminTaxes); // Question Is the if loop necessary if the function has a require on the same argument
            }                                           // (require inProgress[_index] == true) cf. line 111
        }
    }  

    //the admin refound all remaining milestones
    function refoundAllAdmin() external checkIfFactory {
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                refoundMilestoneInternal(i, adminTaxes);
            }
            //idée : sortir les transfers de la boucle pour réduir les gaz fees
        }
    }   

    //l'admin déverrouille la milestone numéro "_index"  !! 1rst index = 0
    function unlockMilestoneAdmin(uint _index ) external checkIfFactory {
        unlockMilestoneInternal(_index, adminTaxes);
    }

    //l'admin rembourse la milestone numéro "_index"  !! 1rst index = 0
    function refoundMilestoneAdmin(uint _index) external checkIfFactory {
        refoundMilestoneInternal(_index, adminTaxes);
    }

    //////////////////////////Privates Functions:///////////////////////////

    function refoundMilestoneInternal(uint _index, uint _taxes) private{
        require(inProgress[_index] == true);
        uint taxes = weiPrices[_index]*_taxes/100;
        uint amount = weiPrices[_index]-taxes;
        buyer.transfer(amount);
        admin.transfer(taxes);
        inProgress[_index]=false;
    }

    function unlockMilestoneInternal(uint _index, uint _taxes) private{
        require(inProgress[_index] == true);
        uint taxes = weiPrices[_index]*_taxes/100;
        uint amount = weiPrices[_index]-taxes;
        seller.transfer(amount);
        admin.transfer(taxes);
        inProgress[_index]=false;
    } 
}