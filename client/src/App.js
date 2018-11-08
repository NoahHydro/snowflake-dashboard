// Imports

import Oxide from "./build/contracts/Oxide.json"
import Snowflake from "./build/contracts/Snowflake.json"
import ERC20 from "./build/contracts/ERC20.json"
import truffleContract from "truffle-contract"
import React, { Component } from "react"
import getWeb3 from "./utils/getWeb3"
import "./App.css"

// UX

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'
import { faUser, faUsers, faShareAlt, faUserTag, faStar, faShieldAlt, faLink, faStreetView, faCheck, faTimes , faDiceFive, faEnvelope, faWallet } from '@fortawesome/free-solid-svg-icons'

import hydroTitle from "./graphics/hydrogenTitle.png"
import hydroLogo from "./graphics/hydrogenLogo.png"
import tokenLogo from "./graphics/tokenLogo.png"

import { ProgressTracker } from '@atlaskit/progress-tracker';
import FieldText, { FieldTextStateless } from '@atlaskit/field-text';
import { Segment, Icon, Table } from 'semantic-ui-react'
import Button from "@atlaskit/button"

// Constants
const snowflakeAddress = "0x8b8B004aBF1eE64e23D6088B73873898d8408A6d"
const oxideAddress = "0x0c73613d03be72db498ebec2690e149f7ad5019f"
const hydroAddress = "0x4959c7f62051D6b2ed6EaeD3AAeE1F961B145F20"
const tokenMetric = parseFloat(Math.pow(10,18))
const items = [
  {
    id: '1',
    label: '0 Punters',
    percentageComplete: 0,
    status: 'current',
    href: '#',
  },
  {
    id: '2',
    label: '1 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '3',
    label: '2 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '4',
    label: '3 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '5',
    label: '4 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '6',
    label: '5 Punters',
    percentageComplete: 0,
    status: 'current',
    href: '#',
  },
  {
    id: '6',
    label: '6 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '7',
    label: '7 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '8',
    label: '8 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '9',
    label: '9 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },
  {
    id: '10',
    label: '10 Punters',
    percentageComplete: 0,
    status: 'unvisited',
    href: '#',
  },

];
const completedStages = [
  {
    id: '1',
    label: '1 Punter',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '2',
    label: '2 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '3',
    label: '3 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '4',
    label: '4 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '5',
    label: '5 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '6',
    label: '6 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '7',
    label: '7 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '8',
    label: '8 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '9',
    label: '9 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
  {
    id: '10',
    label: '10 Punters',
    percentageComplete: 100,
    status: 'visited',
    href: '#',
  },
];



class App extends Component {


  constructor(props) {
    super(props)

    this.state = { leaderboard: [[],[],[],[]] , web3: null, accounts: null, contract: null, current: 1, items };

  }

  logAmount = (event) => this.setState({amount: parseFloat(event.target.value*tokenMetric).toFixed(2) })

  componentDidMount = async () => {
    try {

      const web3 = await getWeb3();
      const accounts = await web3.eth.getAccounts();
      const hydrogenOxide = truffleContract(Oxide);
      const hydrogenToken = truffleContract(ERC20);
      const hydrogenSnowflake = truffleContract(Snowflake);
      hydrogenToken.setProvider(web3.currentProvider);
      hydrogenOxide.setProvider(web3.currentProvider);
      hydrogenSnowflake.setProvider(web3.currentProvider);
      const snow = await hydrogenSnowflake.at(snowflakeAddress);
      const water = await hydrogenSnowflake.at(hydroAddress);
      const gas = await hydrogenOxide.at(oxideAddress);

      await this.setState({ web3, account: accounts[0], token: water, identity: snow, dapp: gas  });

      await this.initiate()

    } catch (error) {
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`
      );
      console.log(error);
    }
  };

  initiate = async () => {

    await this.getPot()
    await this.getRound()
    await this.getWinner()
    await this.getSnowflake()
    await this.getLeaderboard()
    await this.getSnowflakeBalance()
    await this.state.dapp.oxideLength()
    .then((result, error) => {
      if(result){ console.log(result, "Query confirmed");
                  if(parseInt(result) != 0) {
                    this.checkPunters(parseInt(result))
                    this.setState({punters: parseInt(result) }) }
      } else if (error) { console.log(error, "Error confirmed")}
    })

  }

  checkPunters = (value) => {

    if(value > this.state.punters
      || this.state.punters == undefined){
      for(var x = 0; x < value ; x++){
        this.next();
      }
    }
   else if(value < this.state.punters){
          for(var x = 0; x < value ; x++){
            this.prev();
          }
        }
  }

  next() {
    const currentId = this.state.current;
    const completed = {
      id: `${currentId}`,
      label: `${currentId-1} Punters`,
      percentageComplete: 100,
      status: 'Complete',
      href: '#',
    };
    const nextId = currentId + 1;
    const next = {
      id: `${nextId}`,
      label: `${nextId-1} Punters`,
      percentageComplete: 0,
      status: 'Present',
      href: '#',
    };

    const newstages = this.state.items.map(x => {
      if (x.id === `${currentId}`) {
        return completed;
      } else if (x.id === `${nextId}`) {
        return next;
      }
      return x;
    });

    this.setState({
      current: nextId,
      items: newstages,
    });
  }

  prev() {
    const currentId = this.state.current;
    const completed = {
      id: `${currentId}`,
      label: `${currentId-1} Punters`,
      percentageComplete: 0,
      status: 'unvisited',
      href: '#',
    };
    const prevId = currentId - 1;
    const prev = {
      id: `${prevId}`,
      label: `${prevId-1} Punters`,
      percentageComplete: 0,
      status: 'current',
      href: '#',
    };

    const newstages = this.state.items.map(x => {
      if (x.id === `${currentId}`) {
        return completed;
      } else if (x.id === `${prevId}`) {
        return prev;
      }
      return x;
    });

    this.setState({
      current: prevId,
      items: newstages,
    });
  }

  reset() {
    this.setState({
      current: 1,
      items,
    });
  }

  completeAll() {
    this.setState({
      current: 6,
      items: completedStages,
    });
  }

  initaliseDapp = async () => {

    return await this.state.dapp.oxideConfig(snowflakeAddress, hydroAddress,
      {from: this.state.account, value: tokenMetric }).then((result, error) => {
      if(result){ console.log(result, "Initialisation confirmed");
      } else if(!result){ console.log(error, "Error confirmed"); }
    })

  }


  getRound = async () => {

    return await this.state.dapp.roundCount()
    .then((result, error) => {
      if(result){ console.log(result, "Count confirmed");
                  this.setState({count: parseInt(result) })
    } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  placeBet = async () => {

    return await this.state.dapp.oxideBet(this.state.amount,
      {from: this.state.account }).then((result, error) => {
      if(result){ console.log(result, "Bet confirmed");
    } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  getPot = async () => {

    return await this.state.dapp.oxideFund()
    .then((result, error) => {
      if(result){ this.setState({pot: parseFloat(result/tokenMetric).toFixed(2)})
                  console.log(result, "Balance confirmed");
      } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  getSnowflake = async () => {

    return await this.state.identity.getHydroId(this.state.account)
    .then((result, error) => {
      if(result){ this.setState({id: result})
                  console.log(result, "HydroId confirmed");
      } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  findSnowflake = async (array) => {

    var result;
    for(var v = 0; v < array[0].length; v++ ){
      result = await this.insertSnowflake(array,array[0][v])
    }
    return result;

  }

  insertSnowflake = async (array,subject) => {

    console.log(array,subject)

    return await this.state.identity.getHydroId(subject)
    .then((result, error) => {
      if(result){ array[1].push(result)
                  console.log(result, "HydroId confirmed");
                  return array;
      } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  getLeaderboard = async () => {

    return await this.state.dapp.scoreLog({}, { fromBlock: 0, toBlock: 'latest' }).get((error, eventResult) => {
    if (error) { console.log(error);
    } else {
      var delta = 0;
      var array = [[],[],[],[]];
      for(var x = 0; x < eventResult.length; x++ ){
        var valid = JSON.stringify(eventResult[x].args.roundInt).replace(/["]+/g, '')
        if(valid == this.state.count){
          var user = JSON.stringify(eventResult[x].args.wagerUser).replace(/["]+/g, '')
          var roll = JSON.stringify(eventResult[x].args.entropyRoll).replace(/["]+/g, '')
          var amount = JSON.stringify(eventResult[x].args.oxideAmount).replace(/["]+/g, '')
          array[0].push(user)
          array[2].push(roll)
          array[3].push(amount)
          delta++;
          }
      }
      if(delta != 0){
      this.findSnowflake(array).then((result) => {
        this.setState({leaderboard: result})
      })
    }
  }
})

}


  getWinner = async () => {

    return await this.state.dapp.winnerAlert({}, { fromBlock: 0, toBlock: 'latest' }).get((error, eventResult) => {
    if (error) { console.log(error);
    } else {
      for(var x = 0; x < eventResult.length; x++ ){
        var user = JSON.stringify(eventResult[x].args.winningUser).replace(/["]+/g, '')
        var hydroId = JSON.stringify(eventResult[x].args.hydroId).replace(/["]+/g, '')
        var amount = JSON.stringify(eventResult[x].args.jackPot).replace(/["]+/g, '')
        var round = JSON.stringify(eventResult[x].args.roundInt).replace(/["]+/g, '')
        console.log(user, round)
        if(parseInt(round) == this.state.count-1){
          this.setState({winner: user, winningId: hydroId, winnings: parseFloat(amount/tokenMetric).toFixed(2)})
        }
      }
    }
  })

  }

  getSnowflakeBalance = async () => {

    return await this.state.identity.snowflakeBalance(this.state.id)
    .then((result, error) => {
      if(result){ this.setState({snowflake: parseFloat(result/tokenMetric).toFixed(2)})
                  console.log(result, "HydroId confirmed");
      } else if(!result) { console.log(error, "Error confirmed"); }
    })

  }

  render() {

    return (
    <div className="App">


    <div className="oxideTitle">
      <img className="titleImage" src={hydroLogo}/>
      <h1 className="titleName"> Hydrogen Oxide </h1>

    </div>

    <div className="oxideStats">

      <div className="hydroPot">
        <img className="tokenLogo" src={tokenLogo}/>
        <b>Pot: {this.state.pot} </b>
      </div>
      <div className="oxideTracker">
      <Segment raised>
      <ProgressTracker items={this.state.items}/>
      </Segment>
      </div>

    </div>

    <div className="oxideLeaderboard">

    <Table color="blue" key="blue" inverted compact celled>

      <div className="leaderboardHeader">
       <Table.Header className="leaderboardHeader">
         <Table.Row>
           <Table.HeaderCell textAlign="center" colSpan='4'>
           <FontAwesomeIcon color="white" icon={faUsers} size='lg'/>
           &nbsp;&nbsp;Leaderboard
           </Table.HeaderCell>
         </Table.Row>
         <Table.Row>
           <Table.HeaderCell textAlign="center" colSpan='1'>
           <FontAwesomeIcon color="white" icon={faWallet} size='lg'/>
           &nbsp;&nbsp;Address
           </Table.HeaderCell>
           <Table.HeaderCell textAlign="center" colSpan='1'>
           <FontAwesomeIcon color="white" icon={faUserTag} size='lg'/>
           &nbsp;&nbsp;HydroId
           </Table.HeaderCell>
           <Table.HeaderCell textAlign="center" colSpan='1'>
           <FontAwesomeIcon color="white" icon={faDiceFive} size='lg'/>
           &nbsp;&nbsp;Roll
           </Table.HeaderCell>
           <Table.HeaderCell textAlign="center" colSpan='1'>
           <FontAwesomeIcon color="white" icon={faStar} size='lg'/>
           &nbsp;&nbsp;Oxide
           </Table.HeaderCell>
         </Table.Row>
         </Table.Header>
         </div>

      <div className="leaderboardBody">
       <Table.Body>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][0]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][0]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][0]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][0]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][1]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][1]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][1]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][1]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][2]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][2]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][2]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][2]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][3]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][3]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][3]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][3]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][4]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][4]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][4]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][4]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][5]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][5]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][5]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][5]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][6]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][6]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][6]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][6]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][7]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][7]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][7]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][7]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][8]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][8]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][8]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][8]}</Table.Cell>
         </Table.Row>
         <Table.Row>
           <Table.Cell textAlign="center">{this.state.leaderboard[0][9]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[1][9]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[2][9]}</Table.Cell>
           <Table.Cell textAlign="center">{this.state.leaderboard[3][9]}</Table.Cell>
         </Table.Row>
       </Table.Body>
       </div>

     </Table>

    </div>

      <div className="oxideBet">

      <Segment raised>

      <div className="snowflakeBalance">
        <FontAwesomeIcon color="#0075EC" className="tokenLogo" icon={faWallet} size='lg'/>
        &nbsp;&nbsp;Snowflake: <b>{this.state.snowflake} </b></div>
      <div className="oxideInput"><FieldText placeholder="HYDRO Amount" type="number" onChange={this.logAmount} /></div>
      <Button className="oxideButton" appearance="primary" onClick={this.placeBet} > Generate Oxide </Button>
      </Segment>

      </div>

      <div className="oxideAcc">
      <Segment raised>

      <div className="oxideAccount"><FontAwesomeIcon color="#0075EC" icon={faUserTag} size='lg'/>&nbsp;&nbsp;Account: <b>{this.state.account}</b></div>
      <div className="oxideId"><FontAwesomeIcon color="#0075EC" icon={faStreetView} size='lg'/>&nbsp;&nbsp;HydroId: <b> {this.state.id} </b></div>

        </Segment>

        </div>

      <div className="oxideWinner">

      <Segment raised>

      <div className="winningStar"><FontAwesomeIcon color="#0075EC" icon={faStar} size='2x'/> <b>Winner</b></div>
      <br></br>
      <p><FontAwesomeIcon color="#0075EC" className="tokenLogo" icon={faUserTag} size='lg'/>
      &nbsp;&nbsp;HydroId; {this.state.winningId}</p>
      <br></br>
      <p><FontAwesomeIcon color="#0075EC" className="tokenLogo" icon={faDiceFive} size='lg'/>
      &nbsp;&nbsp;Payout: {this.state.winnings}</p>
      <br></br>
      </Segment>

      </div>

    </div>

    );
  }
}

export default App;
