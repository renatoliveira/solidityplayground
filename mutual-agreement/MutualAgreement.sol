// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract MutualAgreement {
    
    // makes the mediator able to withdraw funds
    address payable mediator;
    
    // list of agreements in this contract (using arrays is not optimal!)
    Agreement[] public agreements;
    
    // variables to indicate how much wei was transacted
    // and the current balance
    uint public totalAgreed = 0;
    uint public balance = 0;
    
    // agreement between two parties (Alice and Bob)
    struct Agreement {
        address alice;
        address bob;
        bool alice_agreed;
        bool bob_agreed;
        uint value;
    }
    
    constructor () {
        mediator = msg.sender;
    }
    
    // modifier for functions that only the mediator can run
    modifier ownerOnly() {
        require(msg.sender == mediator, "You are not the mediator for this contract.");
        _;
    }
    
    // Modifier for functions that only those two involved in the agreement
    // can execute (Alice and Bob). The mediator won't be able to run this
    // unless they are one of the parties.
    modifier onlyParties(uint agreement_id) {
        // signing user must be alice or bob, not a third party
        require(agreements[agreement_id].alice == msg.sender || agreements[agreement_id].bob == msg.sender, "You are not part of this negotiation.");
        _;
    }
    
    // Function to check if the agreement is not yet finished
    modifier agreementIsOpen(uint agreement_id) {
        require(!agreements[agreement_id].alice_agreed || !agreements[agreement_id].bob_agreed, "Agreement is finished.");
        _;
    }
    
    // Creates a new agreement proposal 
    // As in: "Alice sends Bob a new proposal."
    function createProposal(address _with) public payable returns(uint) {
        agreements.push(Agreement({
            alice: msg.sender,
            bob: _with,
            alice_agreed: false,
            bob_agreed: false,
            value: msg.value
        }));
        return agreements.length;
    }
    
    // Both parties can add value to the agreement
    function addValue(uint agreement_id) onlyParties(agreement_id) agreementIsOpen(agreement_id) public payable {
        agreements[agreement_id].value += msg.value;
    }
    
    // Returns agreement status between the two parties
    function isSigned(uint agreement_id) public view returns(bool) {
        return agreements[agreement_id].alice_agreed && agreements[agreement_id].bob_agreed;
    }
    
    // Finishes the agreement and adds the funds to the contract's
    // balance when the agreement is completed.
    function finishAgreement(uint agreement_id) private {
        require(isSigned(agreement_id), "Agreement is not signed by both parties.");
        balance += agreements[agreement_id].value;
        totalAgreed += agreements[agreement_id].value;
    }
    
    // The mediator/owner can withdraw funds if they want.
    function withdraw(uint amount) ownerOnly() public payable {
        require(amount <= balance, "Not enough funds!");
        balance -= amount;
        mediator.transfer(amount);
    }
    
    // Both parties can sign the agreement with this function.
    // If the agreement is signed ("isSigned"), then the Agreement
    // is finished between those two.
    function signAgreement(uint agreement_id) onlyParties(agreement_id) agreementIsOpen(agreement_id) public {
        if (agreements[agreement_id].alice == msg.sender) {
            require(!agreements[agreement_id].alice_agreed, "You already signed this agreement.");
            agreements[agreement_id].alice_agreed = true;
        }
        
        else if (agreements[agreement_id].bob == msg.sender) {
            require(!agreements[agreement_id].bob_agreed, "You already signed this agreement.");
            agreements[agreement_id].bob_agreed = true;
        }
        
        if (isSigned(agreement_id)) {
            finishAgreement(agreement_id);
        }
    }
}
