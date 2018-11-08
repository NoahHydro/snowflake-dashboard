pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./AddressSet.sol";

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface SnowflakeResolver {
    function callOnSignUp() external returns (bool);
    function onSignUp(string hydroId, uint allowance) external returns (bool);
    function callOnRemoval() external returns (bool);
    function onRemoval(string hydroId) external returns(bool);
}

interface ClientRaindrop {
    function getUserByAddress(address _address) external view returns (string userName);
    function isSigned(
        address _address, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s
    ) external pure returns (bool);
}

interface ViaContract {
    function snowflakeCall(address resolver, string hydroIdFrom, string hydroIdTo, uint amount, bytes _bytes) external;
    function snowflakeCall(address resolver, string hydroIdFrom, address to, uint amount, bytes _bytes) external;
}

contract Snowflake is Ownable {
    using SafeMath for uint;
    using AddressSet for AddressSet.Set;

    // hydro token wrapper variable
    mapping (string => uint) internal deposits;

    // signature variables
    uint signatureTimeout;
    mapping (bytes32 => bool) signatureLog;

    // lookup mappings -- accessible only by wrapper functions
    mapping (string => Identity) internal directory;
    mapping (address => string) internal addressDirectory;
    mapping (bytes32 => string) internal initiatedAddressClaims;

    // admin/contract variables
    address public clientRaindropAddress;
    address public hydroTokenAddress;

    AddressSet.Set resolverWhitelist;

    constructor() public {
        setSignatureTimeout(7200);
    }

    // identity structures
    struct Identity {
        address owner;
        AddressSet.Set addresses;
        AddressSet.Set resolvers;
        mapping(address => uint) resolverAllowances;
    }

    // checks whether the given address is owned by a token (does not throw)
    function hasToken(address _address) public view returns (bool) {
        return bytes(addressDirectory[_address]).length != 0;
    }

    // enforces that a particular address has a token
    modifier _hasToken(address _address, bool check) {
        require(hasToken(_address) == check, "The transaction sender does not have a Snowflake.");
        _;
    }

    // gets the HydroID for an address (throws if address doesn't have a HydroID or doesn't have a snowflake)
    function getHydroId(address _address) public view returns (string hydroId) {
        require(hasToken(_address), "The address does not have a hydroId");
        return addressDirectory[_address];
    }

    // allows whitelisting of resolvers
    function whitelistResolver(address resolver) public {
        resolverWhitelist.insert(resolver);
        emit ResolverWhitelisted(resolver);
    }

    function isWhitelisted(address resolver) public view returns(bool) {
        return resolverWhitelist.contains(resolver);
    }

    function getWhitelistedResolvers() public view returns(address[]) {
        return resolverWhitelist.members;
    }

    // set the signature timeout
    function setSignatureTimeout(uint newTimeout) public {
        require(newTimeout >= 1800, "Timeout must be at least 30 minutes.");
        require(newTimeout <= 604800, "Timeout must be less than a week.");
        signatureTimeout = newTimeout;
    }

    // set the raindrop and hydro token addresses
    function setAddresses(address clientRaindrop, address hydroToken) public onlyOwner {
        clientRaindropAddress = clientRaindrop;
        hydroTokenAddress = hydroToken;
    }

    // token minting
    function mintIdentityToken() public _hasToken(msg.sender, false) {
        _mintIdentityToken(msg.sender);
    }

    function mintIdentityTokenDelegated(address _address, uint8 v, bytes32 r, bytes32 s)
        public _hasToken(_address, false)
    {
        ClientRaindrop clientRaindrop = ClientRaindrop(clientRaindropAddress);
        require(
            clientRaindrop.isSigned(
                _address, keccak256(abi.encodePacked("Create Snowflake", _address)), v, r, s
            ),
            "Permission denied."
        );
        _mintIdentityToken(_address);
    }

    function _mintIdentityToken(address _address) internal {
        ClientRaindrop clientRaindrop = ClientRaindrop(clientRaindropAddress);
        string memory hydroId = clientRaindrop.getUserByAddress(_address);

        Identity storage identity = directory[hydroId];

        identity.owner = _address;
        identity.addresses.insert(_address);

        addressDirectory[_address] = hydroId;

        emit SnowflakeMinted(hydroId);
    }

    // wrappers that enable modifying resolvers
    function addResolvers(address[] resolvers, uint[] withdrawAllowances) public _hasToken(msg.sender, true) {
        _addResolvers(addressDirectory[msg.sender], resolvers, withdrawAllowances);
    }

    function addResolversDelegated(
        string hydroId, address[] resolvers, uint[] withdrawAllowances, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) public
    {
        require(directory[hydroId].owner != address(0), "Must initiate claim for a HydroID with a Snowflake");
        // solium-disable-next-line security/no-block-members
        require(timestamp.add(signatureTimeout) > block.timestamp, "Message was signed too long ago.");

        ClientRaindrop clientRaindrop = ClientRaindrop(clientRaindropAddress);
        require(
            clientRaindrop.isSigned(
                directory[hydroId].owner,
                keccak256(abi.encodePacked("Add Resolvers", resolvers, withdrawAllowances, timestamp)),
                v, r, s
            ),
            "Permission denied."
        );

        _addResolvers(hydroId, resolvers, withdrawAllowances);
    }

    function _addResolvers(
        string hydroId, address[] resolvers, uint[] withdrawAllowances
    ) internal {
        require(resolvers.length == withdrawAllowances.length, "Malformed inputs.");
        Identity storage identity = directory[hydroId];

        for (uint i; i < resolvers.length; i++) {
            require(resolverWhitelist.contains(resolvers[i]), "The given resolver is not on the whitelist.");
            require(!identity.resolvers.contains(resolvers[i]), "Snowflake has already set this resolver.");
            SnowflakeResolver snowflakeResolver = SnowflakeResolver(resolvers[i]);
            identity.resolvers.insert(resolvers[i]);
            identity.resolverAllowances[resolvers[i]] = withdrawAllowances[i];
            if (snowflakeResolver.callOnSignUp()) {
                require(
                    snowflakeResolver.onSignUp(hydroId, withdrawAllowances[i]),
                    "Sign up failure."
                );
            }
            emit ResolverAdded(hydroId, resolvers[i], withdrawAllowances[i]);
        }
    }

    function changeResolverAllowances(address[] resolvers, uint[] withdrawAllowances)
        public _hasToken(msg.sender, true)
    {
        _changeResolverAllowances(addressDirectory[msg.sender], resolvers, withdrawAllowances);
    }

    function changeResolverAllowancesDelegated(
        string hydroId, address[] resolvers, uint[] withdrawAllowances, uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) public
    {
        require(directory[hydroId].owner != address(0), "Must initiate claim for a HydroID with a Snowflake");

        bytes32 _hash = keccak256(
            abi.encodePacked("Change Resolver Allowances", resolvers, withdrawAllowances, timestamp)
        );

        require(signatureLog[_hash] == false, "Signature was already submitted");
        signatureLog[_hash] = true;

        ClientRaindrop clientRaindrop = ClientRaindrop(clientRaindropAddress);
        require(clientRaindrop.isSigned(directory[hydroId].owner, _hash, v, r, s), "Permission denied.");

        _changeResolverAllowances(hydroId, resolvers, withdrawAllowances);
    }

    function _changeResolverAllowances(string hydroId, address[] resolvers, uint[] withdrawAllowances) internal {
        require(resolvers.length == withdrawAllowances.length, "Malformed inputs.");

        Identity storage identity = directory[hydroId];

        for (uint i; i < resolvers.length; i++) {
            require(identity.resolvers.contains(resolvers[i]), "Snowflake has not set this resolver.");
            identity.resolverAllowances[resolvers[i]] = withdrawAllowances[i];
            emit ResolverAllowanceChanged(hydroId, resolvers[i], withdrawAllowances[i]);
        }
    }

    function removeResolvers(address[] resolvers, bool force) public _hasToken(msg.sender, true) {
        Identity storage identity = directory[addressDirectory[msg.sender]];

        for (uint i; i < resolvers.length; i++) {
            require(identity.resolvers.contains(resolvers[i]), "Snowflake has not set this resolver.");
            identity.resolvers.remove(resolvers[i]);
            delete identity.resolverAllowances[resolvers[i]];
            if (!force) {
                SnowflakeResolver snowflakeResolver = SnowflakeResolver(resolvers[i]);
                if (snowflakeResolver.callOnRemoval()) {
                    require(
                        snowflakeResolver.onRemoval(addressDirectory[msg.sender]),
                        "Removal failure."
                    );
                }
            }
            emit ResolverRemoved(addressDirectory[msg.sender], resolvers[i]);
        }
    }

    // functions to read token values (does not throw)
    function getDetails(string hydroId) public view returns (
        address owner,
        address[] resolvers,
        address[] ownedAddresses,
        uint256 balance
    ) {
        Identity storage identity = directory[hydroId];
        return (
            identity.owner,
            identity.resolvers.members,
            identity.addresses.members,
            deposits[hydroId]
        );
    }

    // check resolver membership (does not throw)
    function hasResolver(string hydroId, address resolver) public view returns (bool) {
        Identity storage identity = directory[hydroId];
        return identity.resolvers.contains(resolver);
    }

    // check address ownership (does not throw)
    function ownsAddress(string hydroId, address _address) public view returns (bool) {
        Identity storage identity = directory[hydroId];
        return identity.addresses.contains(_address);
    }

    // check resolver allowances (does not throw)
    function getResolverAllowance(string hydroId, address resolver) public view returns (uint withdrawAllowance) {
        Identity storage identity = directory[hydroId];
        return identity.resolverAllowances[resolver];
    }

    // allow contract to receive HYDRO tokens
    function receiveApproval(address sender, uint amount, address _tokenAddress, bytes _bytes) public {
        require(msg.sender == _tokenAddress, "Malformed inputs.");
        require(_tokenAddress == hydroTokenAddress, "Sender is not the HYDRO token smart contract.");

        address recipient;
        if (_bytes.length == 20) {
            assembly { // solium-disable-line security/no-inline-assembly
                recipient := div(mload(add(add(_bytes, 0x20), 0)), 0x1000000000000000000000000)
            }
        } else {
            recipient = sender;
        }
        require(hasToken(recipient), "Invalid token recipient");

        ERC20 hydro = ERC20(_tokenAddress);
        require(hydro.transferFrom(sender, address(this), amount), "Unable to transfer token ownership.");

        deposits[addressDirectory[recipient]] = deposits[addressDirectory[recipient]].add(amount);

        emit SnowflakeDeposit(addressDirectory[recipient], sender, amount);
    }

    function snowflakeBalance(string hydroId) public view returns (uint) {
        return deposits[hydroId];
    }

    // transfer snowflake balance from one snowflake holder to another
    function transferSnowflakeBalance(string hydroIdTo, uint amount) public _hasToken(msg.sender, true) {
        _transfer(addressDirectory[msg.sender], hydroIdTo, amount);
    }

    // withdraw Snowflake balance to an external address
    function withdrawSnowflakeBalance(address to, uint amount) public _hasToken(msg.sender, true) {
        _withdraw(addressDirectory[msg.sender], to, amount);
    }

    // allows resolvers to transfer allowance amounts to other snowflakes (throws if unsuccessful)
    function transferSnowflakeBalanceFrom(string hydroIdFrom, string hydroIdTo, uint amount) public {
        handleAllowance(hydroIdFrom, amount);
        _transfer(hydroIdFrom, hydroIdTo, amount);
    }

    // allows resolvers to withdraw allowance amounts to external addresses (throws if unsuccessful)
    function withdrawSnowflakeBalanceFrom(string hydroIdFrom, address to, uint amount) public {
        handleAllowance(hydroIdFrom, amount);
        _withdraw(hydroIdFrom, to, amount);
    }

    // allows resolvers to send withdrawal amounts to arbitrary smart contracts 'to' hydroIds (throws if unsuccessful)
    function withdrawSnowflakeBalanceFromVia(
        string hydroIdFrom, address via, string hydroIdTo, uint amount, bytes _bytes
    ) public {
        handleAllowance(hydroIdFrom, amount);
        _withdraw(hydroIdFrom, via, amount);
        ViaContract viaContract = ViaContract(via);
        viaContract.snowflakeCall(msg.sender, hydroIdFrom, hydroIdTo, amount, _bytes);
    }

    // allows resolvers to send withdrawal amounts 'to' addresses via arbitrary smart contracts
    function withdrawSnowflakeBalanceFromVia(
        string hydroIdFrom, address via, address to, uint amount, bytes _bytes
    ) public {
        handleAllowance(hydroIdFrom, amount);
        _withdraw(hydroIdFrom, via, amount);
        ViaContract viaContract = ViaContract(via);
        viaContract.snowflakeCall(msg.sender, hydroIdFrom, to, amount, _bytes);
    }

    function _transfer(string hydroIdFrom, string hydroIdTo, uint amount) internal returns (bool) {
        require(directory[hydroIdTo].owner != address(0), "Must transfer to an HydroID with a Snowflake");

        require(deposits[hydroIdFrom] >= amount, "Cannot withdraw more than the current deposit balance.");
        deposits[hydroIdFrom] = deposits[hydroIdFrom].sub(amount);
        deposits[hydroIdTo] = deposits[hydroIdTo].add(amount);

        emit SnowflakeTransfer(hydroIdFrom, hydroIdTo, amount);
    }

    function _withdraw(string hydroIdFrom, address to, uint amount) internal {
        require(to != address(this), "Cannot transfer to the Snowflake smart contract itself.");

        require(deposits[hydroIdFrom] >= amount, "Cannot withdraw more than the current deposit balance.");
        deposits[hydroIdFrom] = deposits[hydroIdFrom].sub(amount);
        ERC20 hydro = ERC20(hydroTokenAddress);
        require(hydro.transfer(to, amount), "Transfer was unsuccessful");
        emit SnowflakeWithdraw(to, amount);
    }

    function handleAllowance(string hydroIdFrom, uint amount) internal {
        Identity storage identity = directory[hydroIdFrom];
        require(identity.owner != address(0), "Must withdraw from a HydroID with a Snowflake");

        // check that resolver-related details are correct
        require(identity.resolvers.contains(msg.sender), "Resolver has not been set by from tokenholder.");

        if (identity.resolverAllowances[msg.sender] < amount) {
            emit InsufficientAllowance(hydroIdFrom, msg.sender, identity.resolverAllowances[msg.sender], amount);
            require(false, "Insufficient Allowance");
        }

        identity.resolverAllowances[msg.sender] = identity.resolverAllowances[msg.sender].sub(amount);
    }

    // address ownership functions
    // to claim an address, users need to send a transaction from their snowflake address containing a sealed claim
    // sealedClaims are: keccak256(abi.encodePacked(<address>, <secret>, <hydroId>)),
    // where <address> is the address you'd like to claim, and <secret> is a SECRET bytes32 value.
    function initiateClaimDelegated(string hydroId, bytes32 sealedClaim, uint8 v, bytes32 r, bytes32 s) public {
        require(directory[hydroId].owner != address(0), "Must initiate claim for a HydroID with a Snowflake");

        ClientRaindrop clientRaindrop = ClientRaindrop(clientRaindropAddress);
        require(
            clientRaindrop.isSigned(
                directory[hydroId].owner, keccak256(abi.encodePacked("Initiate Claim", sealedClaim)), v, r, s
            ),
            "Permission denied."
        );

        _initiateClaim(hydroId, sealedClaim);
    }

    function initiateClaim(bytes32 sealedClaim) public _hasToken(msg.sender, true) {
        _initiateClaim(addressDirectory[msg.sender], sealedClaim);
    }

    function _initiateClaim(string hydroId, bytes32 sealedClaim) internal {
        require(bytes(initiatedAddressClaims[sealedClaim]).length == 0, "This sealed claim has been submitted.");
        initiatedAddressClaims[sealedClaim] = hydroId;
    }

    function finalizeClaim(bytes32 secret, string hydroId) public {
        bytes32 possibleSealedClaim = keccak256(abi.encodePacked(msg.sender, secret, hydroId));
        require(
            bytes(initiatedAddressClaims[possibleSealedClaim]).length != 0, "This sealed claim hasn't been submitted."
        );

        // ensure that the claim wasn't stolen by another HydroID during initialization
        require(
            keccak256(abi.encodePacked(initiatedAddressClaims[possibleSealedClaim])) ==
            keccak256(abi.encodePacked(hydroId)),
            "Invalid signature."
        );

        directory[hydroId].addresses.insert(msg.sender);
        addressDirectory[msg.sender] = hydroId;

        emit AddressClaimed(msg.sender, hydroId);
    }

    function unclaim(address[] addresses) public _hasToken(msg.sender, true) {
        for (uint i; i < addresses.length; i++) {
            require(addresses[i] != directory[addressDirectory[msg.sender]].owner, "Cannot unclaim owner address.");
            directory[addressDirectory[msg.sender]].addresses.remove(addresses[i]);
            delete addressDirectory[addresses[i]];
            emit AddressUnclaimed(addresses[i], addressDirectory[msg.sender]);
        }
    }

    // events
    event SnowflakeMinted(string hydroId);

    event ResolverWhitelisted(address indexed resolver);

    event ResolverAdded(string hydroId, address resolver, uint withdrawAllowance);
    event ResolverAllowanceChanged(string hydroId, address resolver, uint withdrawAllowance);
    event ResolverRemoved(string hydroId, address resolver);

    event SnowflakeDeposit(string hydroId, address from, uint amount);
    event SnowflakeTransfer(string hydroIdFrom, string hydroIdTo, uint amount);
    event SnowflakeWithdraw(address to, uint amount);
    event InsufficientAllowance(
        string hydroId, address indexed resolver, uint currentAllowance, uint requestedWithdraw
    );

    event AddressClaimed(address indexed _address, string hydroId);
    event AddressUnclaimed(address indexed _address, string hydroId);
}