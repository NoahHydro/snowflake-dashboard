# Hydrogen Oxide

![Alt text](./UX.png?raw=true "Oxide UX")

### A russian-roulette based gambling dApp, that is dependent on the amount wagered and the entropy roll. Punters have to wager at least 100 HYDRO to contend in a round. Each roll creates an amount of a sub-asset to the ERC20 token based on your HYDRO balance, the amount is computed by multiplying your balance by the entropy roll to the power of itself.

```
result = amount*entropy^(entropy)
```

## Installation

1. Install Truffle globally.
    ```javascript
    npm install -g truffle
    ```

2. Compile the contracts in order to obtain the JSON ABI's and move your build folder to client/src/build

    ```
    truffle compile
    ```

3. Enter the client directory and install dependencies
    ```
    cd client
    ```
    ```
    npm install
    ```

4. Run the local webpack server for the dApp UX
    ```
    // Serves the front-end on http://localhost:3000
    npm run start
    ```

5. Interact with MetaMask and utilising the Snowflake Dashboard to fund your associated HydroId to fund your wagers.

6. Test your luck but don't forget to remember when enough is enough!

## FAQ

* __What is the highest roll?__

  Punters can beat all odds if they roll a 15!

* __What is the lowest roll?__

  Punters can lose it all if they roll a 0!

* __What is the minimum bet?__

  Punters have to wager at least 100 HYDRO to contend in a round.

* __What is the maximum bet?__

  Punters can wager at most 50,000 HYDRO to participate in a round.

* __What's the fee?__

  Each round payout's 100 HYDRO to the creator, punters have to pay their own gas fee's to interact with the dApp.

* __How many people can participate in a round?__

  At minimum 2 people can be active in a round, then a maximum of 10 players can
  participate.
