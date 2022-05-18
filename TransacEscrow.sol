// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract TransacEscrow {

    //variables :
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


    //Statuses {INPROGRESS/true 0, ENDED/false 1}

    constructor(uint _transacId, address payable _seller, address payable _admin, uint[] memory _weiPrices , uint _weiPricesSum) payable{
        require(msg.value >= _weiPricesSum );        
        weiPrices = _weiPrices;
        buyer = payable(msg.sender) ;
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
    function unlockAll() external checkIfBuyer {
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                unlockMilestone(i);
            }
        }
    } 

    //le vendeur rembourse le paiement de toutes les milestones restantes
    function refoundAll() external checkIfSeller {
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                refoundMilestone(i);
            }
        }
    } 

    //l'acheteur déverrouille la milestone numéro "_index"  !! 1rst index = 0
    function unlockMilestone(uint _index) public checkIfBuyer{
        require(inProgress[_index] == true);
        uint _taxes = weiPrices[_index]*userTaxes/100;
        uint _amount = weiPrices[_index]-_taxes;
        seller.transfer(_amount);
        admin.transfer(_taxes);
        inProgress[_index]=false;
    }

    //le vendeur rembourse la milestone numéro "_index"  !! 1rst index = 0
    function refoundMilestone(uint _index) public checkIfSeller{
        require(inProgress[_index]== true);
        uint _amount = weiPrices[_index];
        buyer.transfer(_amount);
        inProgress[_index]=false;
    }


    //////////////////////////////////////////////////////Admin Functions : /////////////////////////////////////////////////////

    //l'admin déverrouille le paiement de toutes les milestones restantes
    function unlockAllAdmin() external checkIfAdmin {
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                unlockMilestoneAdmin(i);
            }
        }
    }  

    //l'admin rembourse toutes les milestones restantes
    function refoundAllAdmin() external checkIfAdmin {
        for (uint256 i = 0; i < milestonesNumber; ++i){
            if(inProgress[i]==true){
                refoundMilestoneAdmin(i);
            }
        }
    }   

    //l'admin déverrouille la milestone numéro "_index"  !! 1rst index = 0
    function unlockMilestoneAdmin(uint _index) public checkIfAdmin {
        require(inProgress[_index] == true);
        uint _taxes = weiPrices[_index]*adminTaxes/100;
        uint _amount = weiPrices[_index]-_taxes;
        seller.transfer(_amount);
        admin.transfer(_taxes);
        inProgress[_index]=false;
    }

    //l'admin rembourse la milestone numéro "_index"  !! 1rst index = 0
    function refoundMilestoneAdmin(uint _index) public checkIfAdmin {
        require(inProgress[_index] == true);
        uint _taxes = weiPrices[_index]*adminTaxes/100;
        uint _amount = weiPrices[_index]-_taxes;
        buyer.transfer(_amount);
        admin.transfer(_taxes);
        inProgress[_index]=false;
    }



}