// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract TransacEscrow {

    //variables :
    address public factory ;
    address payable public buyer ;
    address payable public seller ; 
    address payable public admin ;
    uint public milestonesNumber; //nombre de milestones (taille des array)
    bool[] public inProgress; //état de chaques milestones
    uint[] public weiPrices ; //array des différents prix
    uint weiPricesSum ;
    uint public transacId;
    uint userTaxes = 3; //pourcentage du paiement versé à l'admin lorsque le buyer unlock (refound = taxes free)
    uint adminTaxes = 20; //pourcentage versé à l'admin lors de l'activation d'une fonction admin (refound/unlock)

    //modifiers

    /*
    modifier checkIfBuyer{
        require(msg.sender == buyer, "only callable by buyer");
        _;
    }
    modifier checkIfSeller{
        require(msg.sender == seller, "only callable by seller");
        _;
    }
    modifier checkIfAdmin{
        require(msg.sender == admin, "only callable by admin");
        _;
    }
    */

    modifier checkIfFactory{
        require(msg.sender == factory);
        _;
    }

    //Statuses {INPROGRESS/true 0, ENDED/false 1}

    constructor(uint _transacId, address payable _seller, address payable _admin, uint[] memory _weiPrices , uint _weiPricesSum) payable{
        require(msg.value >= _weiPricesSum );        
        weiPrices = _weiPrices;
        buyer = payable(msg.sender) ; //ATENTION !! msg.senger = factory donc a changer 
        seller = _seller ; 
        admin = _admin ;
        transacId = _transacId;
        milestonesNumber = _weiPrices.length ;
        weiPricesSum = _weiPricesSum ;
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            inProgress[i] = true;
        }
    }


    ////////////////////////////////////////////////////User Functions : ////////////////////////////////////////////////////////

    //l'acheteur déverrouille le paiement de toutes les milestones restantes
    function unlockAll(address _msgSender) external checkIfFactory {
        require(_msgSender == buyer);
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                unlockMilestoneInternal(i, userTaxes);
            }
        }
    } 

    //le vendeur rembourse le paiement de toutes les milestones restantes
    function refoundAll(address _msgSender) external checkIfFactory {
        require(_msgSender == seller);
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                refoundMilestoneInternal(i, userTaxes);
            }
        }
    } 

    //l'acheteur déverrouille la milestone numéro "_index"  !! 1rst index = 0
    function unlockMilestone(uint _index, address _msgSender) public checkIfFactory{
        require(_msgSender == buyer);
        unlockMilestoneInternal(_index, userTaxes);
    }

    //le vendeur rembourse la milestone numéro "_index"  !! 1rst index = 0
    function refoundMilestone(uint _index, address _msgSender) public checkIfFactory{
        require(_msgSender == seller);
        refoundMilestoneInternal(_index, userTaxes);
    }


    //////////////////////////////////////////////////////Admin Functions : /////////////////////////////////////////////////////

    //l'admin déverrouille le paiement de toutes les milestones restantes
    function unlockAllAdmin(address _msgSender) external checkIfFactory {
        require(_msgSender == admin);
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                unlockMilestoneInternal(i, adminTaxes);
            }
        }
    }  

    //l'admin rembourse toutes les milestones restantes
    function refoundAllAdmin(address _msgSender) external checkIfFactory {
        require(_msgSender == admin);
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                refoundMilestoneInternal(i, adminTaxes);
            }
            //idée : sortir les transfers de la boucle pour réduir les gaz fees
        }
    }   

    //l'admin déverrouille la milestone numéro "_index"  !! 1rst index = 0
    function unlockMilestoneAdmin(uint _index , address _msgSender) external checkIfFactory {
        require(_msgSender == admin);
        unlockMilestoneInternal(_index, adminTaxes);
    }

    //l'admin rembourse la milestone numéro "_index"  !! 1rst index = 0
    function refoundMilestoneAdmin(uint _index, address _msgSender) external checkIfFactory {
        require(_msgSender == admin);
        refoundMilestoneInternal(_index, adminTaxes);
    }

    //////////////////////////internal Functions:///////////////////////////

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