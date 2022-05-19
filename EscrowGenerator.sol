// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import './Adminable.sol';
import './TransacEscrow.sol';

//////////questions importantes: /////////////////////
/*
est ce que le msg sender pour les contracts créés est l'adresse de la factorie ??
dans ce cas les require du contract transacEscrow sont inutiles et doivent etre addaptés
 */


contract EscrowGenerator is Adminable {

    mapping(uint=>address) public escrows;


    //create new TransacEscrow
    function newTransacEscrow(uint _transacId, address payable _seller, uint[] memory _weiPrices) external payable{
        uint _weiPricesSum = 0;
        for (uint256 i = 0; i < _weiPrices.length; ++i) {
            _weiPricesSum = ++_weiPrices[i];
        }
        TransacEscrow transac = new TransacEscrow{value: msg.value}(_transacId, _seller, admin, _weiPrices, _weiPricesSum);
        escrows[_transacId]= address(transac);     
    }

    //views
    /*
    function getTransacStatus(uint _transacId) public returns(uint[] memory, bool[] memory){
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        return(transac.weiPrices, transac.inProgress);
    }
    */

    //////////////////user Functions ://///////////////////////
    function unlockMilestone(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockMilestone(_milestoneIndex, msg.sender);
    }

    function unlockAll(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockAll(msg.sender);
    }

    function refoundMilestone(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refoundMilestone(_milestoneIndex, msg.sender);
    }

    function refoundAll(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refoundAll(msg.sender);
    }



    ////////////////admin Functions : //////////////////////////
    function unlockMilestoneAdmin(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockMilestoneAdmin(_milestoneIndex, msg.sender);
    }
    function unlockAllAdmin(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.unlockAllAdmin(msg.sender);
    }
    function refoundMilestoneAdmin(uint _transacId, uint _milestoneIndex) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refoundMilestoneAdmin(_milestoneIndex, msg.sender);
    }
    function refoundAllAdmin(uint _transacId) public{
        TransacEscrow transac = TransacEscrow(escrows[_transacId]);
        transac.refoundAllAdmin(msg.sender);
    }

}