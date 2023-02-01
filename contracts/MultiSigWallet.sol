// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount); // Deposit events
    event Submit(uint256 indexed txId); // Emits event when a transaction is submitted.
    event Approve(address indexed owner, uint256 indexed txId); // Approve a transaction
    event Revoke(address indexed owner, uint256 indexed txId); // Revoke Approval for a transaction
    event Execute(uint256 indexed txId); // Execute a transaction after a sufficient number of approval

    /**
     * Defining a struct to represent a transaction
     **/
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    /**
     * Initializing some STATE VARIABLES for the MultiSig Wallet contract
     * 1. An array of addresses to hold the owners addresses
     * 2. A mapping to quickly check if an address is an owner address
     * 3.
     **/
    address[] public owners;

    mapping(address => bool) public isOwner; // checks if an address is an owner of the multisig wallet

    uint public requiredApprovals; // required number of approvals per transaction

    Transaction[] public transactions; // an array to store all our transactions

    // Mapping to store the approved transactions made by each Multisig owner
    mapping(uint256 => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "unauthorized");
        _;
    }

    modifier txExists(uint256 txId) {
        require(txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notApproved(uint256 txId) {
        require(!approved[txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint256 txId) {
        require(transactions[txId].executed = false, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "owners required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "invalid required number of owners"
        );
        // Save the _owners provided into the owners state variable
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner address"); // disallow zero addresses
            require(!isOwner[owner], "address is already owner"); // check if address is unique

            isOwner[owner] = true;
            owners.push(owner); // Add the new owner into the owners arrat
        }

        // Update the required number of approvers
        requiredApprovals = _requiredApprovals;
    }

    // Enable the multisig wallet to receive Money
    // Emit a receive event when funds are received into the wallet

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Create a SubmitTransaction function
    // Only Owners will be able to submit a transaction
    // calldata is cheaper and is also used since the function is external
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );

        // The index in which the last transaction event will be stored
        // is at the index 1 less of the length of the transaction array
        emit Submit(transactions.length - 1);
    }

    function approveTransaction(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(
        uint256 _txId
    ) private view returns (uint256 count) {
        for (uint256 i; i < owners.length; i++) {
            // if the address at the index specified by i in the owners array of addresses
            // has approved the transaction with id txId, increment count of approval
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function executeTransaction(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(
            _getApprovalCount(_txId) >= requiredApprovals,
            "insufficient approvals"
        );
        Transaction storage transaction = transactions[_txId];

        // update the state of the blockchain
        transaction.executed = true;

        // executing the transaction
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success = true, "tx failed!");

        // Emit event for successful execution of transaction
        emit Execute(_txId);
    }

    function revokeTransaction(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender] = true, "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getNumberOfOwners()
        external
        view
        returns (uint256 number_of_owners)
    {
        return number_of_owners = owners.length;
    }
}
