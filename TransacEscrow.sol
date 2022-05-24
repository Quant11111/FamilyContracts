// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract TransacEscrow {

    //transaction state

    enum TransactionState{ UNCONFIRMED, CONFIRMED, COMPLETED, TRIAL }
    TransactionState thisState = TransactionState.UNCONFIRMED;

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
    uint deploymentTime ;

    //modifiers

    modifier checkIfFactory{
        require(msg.sender == factory);  //ensure that _msgSender isn't faked being feeled manualy while the function is called outside of the factory
        _;
    }
    modifier unconfirmed{
        require(thisState == TransactionState.UNCONFIRMED);
        _;
    }
    modifier confirmed{
        require(thisState == TransactionState.CONFIRMED);
        _;
    }
    modifier completed{
        require(thisState == TransactionState.COMPLETED);
        _;
    }
    modifier trial{
        require(thisState == TransactionState.TRIAL);
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
        deploymentTime = block.timestamp;
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            inProgress[i] = true; //init of the milestonesStateArray
        }
    }

    //////////////////////(thisState == UNCONFIRMED)///////////////////////////////////

    //buyer///////////
    //can autoRefund if no confirmation for 3 days
    function autoRefund(address _msgSender) external checkIfFactory unconfirmed {
        require(block.timestamp >= deploymentTime + 259200); //3days = 259200sec
        require(_msgSender == buyer);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                refundMilestonePrivate(i, 0);
            }
        }
        thisState = TransactionState.COMPLETED;
    } 

    //seller//////////
    //Accept the order
    function acceptOrder(address _msgSender) external checkIfFactory unconfirmed{
        require(_msgSender == seller);
        thisState = TransactionState.CONFIRMED;
    }
    //dont handle thi order and refund the buyer
    function cancellOrder(address _msgSener) external checkIfFactory unconfirmed{
        require(_msgSener == seller);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                refundMilestonePrivate(i, 0);
            }
        }
        thisState = TransactionState.COMPLETED;
    }



    ////////////////////////////////////////////////////(thisState == CONFIRMED) ////////////////////////////////////////////////////////

    //buyer//////////
    //the buyer unlock all remaining milestones
    function unlockAll(address _msgSender) external checkIfFactory confirmed{
        require(_msgSender == buyer);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                unlockMilestonePrivate(i, userTaxes);
            }
        }
    } 
    //the buyer unlock the payment number "_index"  !! 1rst milestone index = 0
    function unlockMilestone(uint _index, address _msgSender) public checkIfFactory confirmed{
        require(_msgSender == buyer);
        unlockMilestonePrivate(_index, userTaxes);
    }

    //seller//////////
    //the seller refund all remaining milestones
    function refundAll(address _msgSender) external checkIfFactory confirmed{
        require(_msgSender == seller);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                refundMilestonePrivate(i, userTaxes);
            }
        }
    } 
    //the seller refund the payment number "_index"  !! 1rst milestone index = 0
    function refundMilestone(uint _index, address _msgSender) public checkIfFactory confirmed{
        require(_msgSender == seller);
        refundMilestonePrivate(_index, userTaxes);
    }


    //Admin////////////////
    //transfer une ou plusieurs milestones(ex 20%refund and 80%unlocked)
    function transferMilestoneAdmin(uint _index, address _msgSender, uint _buyerPercent, uint _sellerPercent) external checkIfFactory{
        require(_msgSender == admin);
        transferMilestone(_index, _buyerPercent, _sellerPercent);

    }
    function transferAllAdmin(address _msgSender, uint _buyerPercent, uint _sellerPercent) external checkIfFactory{
        require(_msgSender == admin);
        require(_buyerPercent + _sellerPercent == 100);
        for (uint256 i = 0; i < weiPrices.length; ++i){
            if(inProgress[i]==true){
                transferMilestone(i, _buyerPercent, _sellerPercent);            }
        }
    }


    //////////////////////////Privates Functions:///////////////////////////

    function refundMilestonePrivate(uint _index, uint _taxes) private{
        require(inProgress[_index] == true);
        uint taxes = weiPrices[_index]*_taxes/100;
        uint amount = weiPrices[_index]-taxes;
        buyer.transfer(amount);
        admin.transfer(taxes);
        inProgress[_index]=false;
    }

    function unlockMilestonePrivate(uint _index, uint _taxes) private{
        require(inProgress[_index] == true);
        uint taxes = weiPrices[_index]*_taxes/100;
        uint amount = weiPrices[_index]-taxes;
        seller.transfer(amount);
        admin.transfer(taxes);
        inProgress[_index]=false;
    } 

    //only used in admin function 
    function transferMilestone(uint _index, uint _buyerPercent, uint _sellerPercent) private{
        require( _buyerPercent + _sellerPercent == 100);
        require(inProgress[_index] == true);
        uint taxes = weiPrices[_index]*adminTaxes/100;
        uint amount = weiPrices[_index]-taxes;
        uint refundAmount = amount*_buyerPercent/100;
        uint unlockedAmount = amount*_sellerPercent/100;
        buyer.transfer(refundAmount);
        seller.transfer(unlockedAmount);
        admin.transfer(taxes);
        inProgress[_index]=false;
    }
}