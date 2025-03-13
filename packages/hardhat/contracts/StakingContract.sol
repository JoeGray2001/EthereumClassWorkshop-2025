// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.26 and less than 0.9.0
pragma solidity >=0.8.26 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "hardhat/console.sol";

// Contract to demonstrate Solidity basics
contract StakingContract {
    // Variables
    address public immutable owner; // public is a visibility modifier that makes the variable accessible from outside the contract

    enum Ethnicity {
        African,
        European,
        Asian
    }

    // Struct
    struct User {
        string name;
        uint8 age;
        Ethnicity ethnicity;
        uint256 balance;
        uint256 index;
        bool exists;
    }

    /**
        Mappings in Solidity (mapping(address => uint256)) do not have a built-in way to check if a key exists 
            because all possible keys default to their zero value if not explicitly set.
        You can use an additional boolean mapping to track whether a key has been set
     */
    mapping(address => User) public users; // users is a mapping that stores all user addresses and their corresponding user objects
    // Array with dynamic size 
    address[] public userAddresses; // userAddresses is an array that stores all user addresses

    // Constants
    // uint256 public constant MAX_PEOPLE = 10;
    uint256 public immutable MAX_PEOPLE = 10;
    bytes32 constant SLOT = 0;

    // Events
    event NumberUpdated(uint256 oldNumber, uint256 newNumber);
    // Indexed parameters help you filter the logs by the indexed parameter
    event UserAdded(address indexed account, string name, uint8 age, uint256 balance);
    event UserWithdrew(address indexed account, string name, uint8 age, uint256 balance);
    // Log of the contract
    event Log(string func, uint256 gas);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Lock implemented using transient state
    modifier lock() {
        assembly {
            if tload(SLOT) { revert(0, 0) }
            tstore(SLOT, 1)
        }
        _;
        assembly {
            tstore(SLOT, 0)
        }
    }

    // Constructor
    constructor(address _owner, uint256 _max_people) {
        owner = _owner;
        MAX_PEOPLE = _max_people;
    }

    // Fallback function must be declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        emit Log("fallback", gasleft());
    }

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {
        emit Log("receive", gasleft());
    }

    /**
        Get the age of the calling address after x years
     */
    function getAge(uint8 _years) public view returns (uint8){
        User memory user = users[msg.sender];
        user.age = user.age + _years;
        return user.age;
    }

    // Pure function
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        // sum and overflow are local variables
        // it might result in overflow; use SafeMath library
        (bool overflow, uint256 sum) = Math.tryAdd(a, b); 
        require (!overflow, "Addition has resulted in an overflow :(");
        return sum;
    }

    /**
        Function returns the number of users in the smart contract
     */
    function getUserCount() public view returns(uint256){
        uint256 count = userAddresses.length;
        return count;
    }

    /**
     * Function that allows users to store Ether in the smart contract
     */
    function addUser(string memory _name, uint8 _age, Ethnicity ethnicity) public payable{
        

        // TODO: use require to check if the user sent ether in the calling transaction
        require(msg.value > 0, "The staking value is 0"); 

        // TODO: use require to check if user already exists or not
        require(users[msg.sender].exists, "User already exists");

        // TODO: use require to check if the users are over the set limit
        require(userAddresses.length < MAX_PEOPLE, string.concat("Users are over the limit of ", Strings.toString(MAX_PEOPLE)));

        // TODO: create the user object in memory
        // memory is temporary storage. User is a struct
        User memory user = User(_name, _age, ethnicity, msg.value, userAddresses.length, true);

        // TODO: store the user in the users key value mapping
        users[msg.sender] = user;

        // TODO: store the user address in the userAddresses array
        userAddresses.push(msg.sender);

        // TODO: emit the UserAdded log
        emit UserAdded(msg.sender, user.name, user.age, user.balance);
    }

    // Return many
    function userDetails(address _address) public view returns (string memory name, uint8 age) {
        User memory user = users[_address];
        return (user.name, user.age);
    }

    /**
     * Function that allows the users to withdraw all the Ether they deposited in the smart contract
     */
    function withdraw() external lock {
        // TODO: get the amount to be withdrawn
        User memory user = users[msg.sender];

        // TODO: use require to check if the user has any money to withdraw
        require(user.balance > 0, "No balance to withdraw");

        // TODO: uncomment below to view print log messages during testing
        string memory name = users[msg.sender].name;
        console.log(string.concat(name, ' <-> withdrawing '));
        
        // TODO: use the call function on an address object to send Ether to the use
        (bool success, ) = msg.sender.call{value: user.balance}("");
        
        // TODO: uncomment below to log if withdrawal fails
        console.log(success ? "withdrawal successful": "withdrawal failed");

        // TODO: use require to check if the transfer was successful
        require(success, "Transfer failed");

        // TODO: uncomment to call the _delete function
        _delete(msg.sender);
    }

    /**
     * Function that deletes the user record from users and userAddresses after withdrawal
     */
    function _delete(address userAddress) internal {
        // TODO: uncomment this to check for user existence
        // NOTE: We could have used require, but we can't illustrate the attack because the sm logic would fail after the first recursive withdrawal
        if (!users[userAddress].exists){
            return;
        }
        
        // TODO: get the user object into memory
        User memory user = users[userAddress];

        // TODO: delete the user from the users mapping
        delete users[userAddress];

        // TODO: delete the user from users and from the userAddresses array
        // NOTE: first re-locate the address in the last position to the position we are deleting
        // NOTE: second edit the re-located user object's index
        address lastPositionAddress = userAddresses[userAddresses.length - 1];
        User storage lastPositionUser = users[lastPositionUserAddress];

        lastPositionUser.index = user.index;

        // TODO: use pop() to remove the last element of the userAddresses array
    }

    // Internal function
    function _internalFunction() internal pure returns (string memory) {
        return "Internal function called";
    }
}

/**
    Inheritance
    List in order of most base-like to most derived
 */
contract ExtendedSolidity is StakingContract {

    constructor(address owner, uint256 _max_people) StakingContract(owner, _max_people){}

    // New function in derived contract
    function getInternalFunctionResult() public pure returns (string memory) {
        return _internalFunction();
    }
}