pragma solidity 0.4.25;

import './SnowflakeResolver.sol';
import './OraclizeI.sol';
import './AddressSet.sol';
import './SafeMath.sol';

interface hydroToken {

    function transfer(address subject, uint amount) external returns (bool);
    function balanceOf(address subject) external view returns (uint);

}

interface Snowflake {

    function withdrawSnowflakeBalanceFrom(string hydroId, address user, uint amount) external;
    function snowflakeBalance(string hydroId) external view returns (uint);
    function getHydroId(address _address) external view returns (string);

}

contract Oxide is SnowflakeResolver, usingOraclize {

    using AddressSet for AddressSet.Set;
    using SafeMath for uint;

    event scoreLog(address wagerUser, uint entropyRoll, uint oxideAmount, uint roundInt);
    event winnerAlert(address winningUser, string hydroId, uint jackPot, uint roundInt);
    event oracleQuery(bytes32 oracleId);

    mapping (address => uint) internal _wager;
    mapping (address => uint) internal _h20;
    AddressSet.Set internal round;
    address public admin = msg.sender;
    address public hydroAddress;
    uint public operationalFee;
    hydroToken public _WATER;
    uint public minimumWager;
    uint public maximumWager;
    uint public roundCount;
    Snowflake public _SNOW;
    uint public highScore;
    address public winner;
    address internal hid;
    uint public tMetric;
    bool public active;
    bool public query;

    modifier _onlyAdmin { require(msg.sender == admin); _; }

    modifier _queryCompleted { require(query == true); _; }

    modifier _isActive { require(active == true); _; }

    constructor () public {
        tMetric = uint(10**18);
        maximumWager = uint(50000).mul(tMetric);
        minimumWager = uint(100).mul(tMetric);
        snowflakeDescription = "Wager game";
        snowflakeName = "Hydrogen Oxide";
        operationalFee = minimumWager;
     }

    function oxideConfig(address snow, address water) public payable _onlyAdmin {
        _WATER = hydroToken(water);
        _SNOW = Snowflake(snow);
        active = true;
        query = true;
    }

    function oxideBet(uint amount) public _queryCompleted _isActive {
        require(amount >= minimumWager && amount <= maximumWager);
        string memory hydroId = _SNOW.getHydroId(msg.sender);
        require(_SNOW.snowflakeBalance(hydroId) >= amount);
        require(!round.contains(msg.sender));
        oxideWager(hydroId, amount);
    }

    function generateH20(address user, uint entropy) internal {
        uint oxide = _wager[user].mul(entropy**entropy);
        emit scoreLog(hid, entropy, oxide, roundCount);
        _h20[user] = oxide;
        delete hid;
    }

    function oxideWager(string hydroId, uint amount) internal {
        _SNOW.withdrawSnowflakeBalanceFrom(hydroId, address(this), amount);
        oraclize_query("WolframAlpha", "random number between 0 and 15");
        if(round.length() == 4){ active = false; }
        _wager[msg.sender] = amount.div(tMetric);
        round.insert(msg.sender);
        hid = msg.sender;
        query = false;
    }

    function __callback(bytes32 id, string result) public {
        require(msg.sender == oraclize_cbAddress());
        generateH20(hid, parseInt(result));
        emit oracleQuery(id);
        query = true;
    }

    function oxideLength() public view returns (uint l) {
        l =  round.length();
    }

    function oxideFund() public view returns (uint f) {
         f =  _WATER.balanceOf(address(this)).sub(operationalFee);
    }

    function stackFees() internal {
        operationalFee = operationalFee.add(minimumWager);
    }

    function withdrawFees() public _onlyAdmin _isActive {
        require(_WATER.transfer(admin, operationalFee));
        operationalFee = minimumWager;
    }

    function oxideWinner() public _onlyAdmin {
        highScore = 0;
        require(round.length() >= 2);
        for(uint x = 0; x < round.length(); x++){
            address subject = round.members[x];
            if(_h20[subject] > highScore){
                highScore = _h20[subject];
                winner = subject;
            }
            delete _wager[subject];
            delete _h20[subject];
        }
        oxidePayout();
    }

    function oxidePayout() internal {
        emit winnerAlert(winner, _SNOW.getHydroId(winner), oxideFund(), roundCount);
        require(_WATER.transfer(winner, oxideFund()));
        active = true;
        roundCount++;
        delete round;
        stackFees();
    }

}
