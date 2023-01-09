// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/** @title A sample Multisig Contract
 * @author Reda Aboutika
 * @notice This contract is for creating a MultiSig wallet
 */
contract MultiSig {
    address[] public owners;
    uint256 public required;

    struct Transaction {
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }

    //AU solution: create a mapping to keep track of transactions
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0);
        require(_required > 0);
        require(_required <= _owners.length);
        owners = _owners;
        required = _required;
    }

    receive() external payable {}

    function executeTransaction(uint _transactionId) internal {
        Transaction storage _tx = transactions[_transactionId];
        require(isConfirmed(_transactionId));
        (bool success, ) = _tx.destination.call{value: _tx.value}(_tx.data);
        require(success);
        _tx.executed = true;
    }

    function transactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function addTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) internal returns (uint256 id) {
        transactions.push(Transaction(_destination, _value, false, _data));
        id = transactions.length - 1;
        return id;
    }

    function confirmTransaction(uint256 _transactionId) public {
        bool owner = false;
        for (uint256 i; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                owner = true;
            }
        }
        //AU solution: create isOwner function and require(isOwner)
        require(owner);
        confirmations[_transactionId][msg.sender] = true;
        if (isConfirmed(_transactionId)) {
            executeTransaction(_transactionId);
        }
    }

    function getConfirmationsCount(uint _transactionId)
        public
        view
        returns (uint256)
    {
        uint numConfirmations = 0;
        for (uint i; i < owners.length; i++) {
            if (confirmations[_transactionId][owners[i]]) {
                numConfirmations++;
            }
        }
        return numConfirmations;
    }

    function submitTransaction(
        address _destination,
        uint _value,
        bytes memory _data
    ) external {
        // AU solution: first create id variable returned from addTransaction
        // then call confirmTransaction with id as argument
        confirmTransaction(addTransaction(_destination, _value, _data));
    }

    function isConfirmed(uint _transactionId) public view returns (bool) {
        return getConfirmationsCount(_transactionId) >= required;
    }
}
