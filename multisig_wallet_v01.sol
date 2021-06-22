pragma solidity 0.8.4;

// This contract is a multi-signature wallet for ether.
// Users need to specify at contract deployment the maximum number of owners.
// Users also need to specify at deployment the minimum number of owners required for approving a transfer.
// Any ethereum address can deposit ether into the contract; it is not limited to owners.


contract wallet {
    
    mapping(address => uint) balance; // To enable getting of contract balances
    mapping(address => uint) ownerIndex; // For checking the owners registry quickly 
    mapping(uint => Transfer) transfers; // A registry of all transfer requests created
    mapping(uint => mapping(address => uint)) approvalIndex; // For quickly checking number of approvals given for a transfer 
    
    
    event ownerAdded(address owner);
    event transferCreated (address recipient, uint amount);
    event transferDone (address recipient, uint amount);
    
    
    uint numOfOwners;
    uint numOfApprovals;
    uint pendingTransfers;
    uint transferID;
    
    address[] owners;
    uint[] transferList;
    
    struct Transfer {
        uint id;
        address transferTo;
        uint transferAmt;
        address[] ownersApproval;
        bool approved;
    }
    
    
    // Create contract by specifying the maximum number of owners and number of approvals needed for transfers
    constructor (uint _persons, uint _approveRequired) {
        require (_persons > 0 && _approveRequired > 0, "Number of owners and number of approvals must be greater than one.");
        require (_approveRequired <= _persons, "Required number of approvals exceeds number of owners.");
        numOfOwners = _persons;
        numOfApprovals = _approveRequired;
        transferID = 0;
        pendingTransfers = 0;
    }
    
    
    function addOwner(address newOwner) public {
        // Ensure owner and approval requirements are already specified
        require(numOfOwners != 0 || numOfApprovals !=0, "Please first specify number of owners and number of approvals needed.");
        // Ensure address to be added is not already in contract
        require (!_ownerExists(newOwner), "Owner already exists in contract.");
        // Ensure number of owners does not exceed limit set for contract
        require(owners.length <= numOfOwners-1, "Number of owners exceeds limit set for contract");
        uint ownerID;
        owners.push(newOwner);
        ownerID = owners.length;
        ownerIndex[newOwner] = ownerID;
        emit ownerAdded (newOwner);
    }
    
    // Public function for anyone to deposit ether into the contract 
    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }
    
    // Public function for checking nominal contract balance (excluding pending transfers)
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    // Public function for checking total amount in pending transfers
    function getTotalPendingTransfers() public view returns(uint){
        return pendingTransfers; 
    }
    
    // Public function for checking the list of owners
    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    // Public function for an owner to create a transfer request    
    // Each new transfer is identified by a transferID
    function transferRequest(address recipient, uint amount) public {
        require (_ownerExists(msg.sender), "Only owners can make transfer requests."); //Ensure only an owner can initiate a transfer request
        require (address(this).balance - pendingTransfers >= amount, "Not enough fund in balance."); //Ensure the contract has more liquid funds for the transfer

        transferID ++;
        transferList.push(transferID);
        transfers[transferID].id = transferID;
        transfers[transferID].transferTo = recipient;
        transfers[transferID].transferAmt = amount;
        transfers[transferID].ownersApproval.push(msg.sender);
        transfers[transferID].approved = false;
        approvalIndex[transferID][msg.sender] = 1;
        pendingTransfers += amount; //Increase the balance of total pending transfers
        emit transferCreated (recipient, amount);
        
        // To approve the transfer if only one approver is specified in contract deployment
        _execTransfer(transferID);
    }
    
    
    // Public function to get all pending transfers not yet approved; zeros in fields returned indicate a transfer has already been executed
    function getPendingTransfers () public view returns (uint[] memory, address[] memory, uint[] memory) {
        uint[] memory tempID = new uint[](transferList.length);
        address[] memory to = new address[](transferList.length);
        uint[] memory amount = new uint[](transferList.length);
        
        for (uint i=1; i<=transferList.length; i++){
            if (transfers[i].approved != true) {
                tempID[i-1] = transfers[i].id;
                to[i-1] = transfers[i].transferTo;
                amount[i-1] = transfers[i].transferAmt;
            }
            
        }

        return (tempID, to, amount);
    }
    
    
    // Public function for owners to approve transfers
    // Approving owner is required to provide the transferID of a pending transaction
    function approveTransfer (uint _transferID) public {
        // Require that only owner can approve transfer
        require (_ownerExists(msg.sender), "Only owners can approve transfer request.");
        // Require that no owner can approve the same transfer more than once
        require (!_ownerAlreadyApproved(_transferID), "This owner already approved the transfer.");
        // To avoid executing transfers already approved previously
        require (transfers[_transferID].approved != true, "This transfer has already been processed.");
        // Ensure _transferID is in the list of pending transactions
        require (_transferID != 0 && _transferID <= transferList.length, "This transfer ID does not exist.");
        
        transfers[_transferID].ownersApproval.push(msg.sender);
        approvalIndex[_transferID][msg.sender] = transfers[_transferID].ownersApproval.length;
        
        _execTransfer(_transferID);
    }    
        
        
    // Private function to check existence of owner address in contract
    function _ownerExists(address _owner) private returns (bool) {
        return (ownerIndex[_owner] != 0);
    }
    
    
    //Private function to check existence of an owner's approval to a specific transfer   
    function _ownerAlreadyApproved(uint _transferID) private returns(bool) {
        return (approvalIndex[_transferID][msg.sender] != 0);
    }
    
    
    // Private function to execute transfer
    function _execTransfer(uint _transferID) private {
        if (transfers[_transferID].ownersApproval.length == numOfApprovals) {
            address _recipient = transfers[_transferID].transferTo;
            uint _amount = transfers[_transferID].transferAmt;
            payable(_recipient).transfer(_amount);
            pendingTransfers -= _amount; // Decrease the balance of total pending transfers
            transfers[_transferID].approved = true;
            emit transferDone(_recipient, _amount);
        }
    }

}    

    
   
  
    

    
    
    
    
   
    

    
    
    
   
    
    
 
    
   

