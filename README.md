# Ethereum Guide

## 1. GETH
#####1.1 install
    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install ethereum
    
GETH is the command line interface to run your node. Apart from interacting via command line, it also provides an interactive console and a JSON-RPC Server.  

#####1.2 interactive console:

    geth console

#####1.3 access node via JSON-RPC api from browser:

    geth --rpc --rpccorsdomain "<<your webserver address>> 


## 2. How to set up an Ethereum Node on a private Blockchain

#####2.1 full start command for node

    geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/home/mgsgde/privateEthereum"
    --genesis "/home/mgsgde/privateEthereum/CustomGenesis.json" console

#####2.2 in detail
* **--rpc** : enables rpc (so that our website can interact with the node) 

* **--rpcport** : port that is used by the webbrowser to interact with the local node

* **--rpccorsdomain** : we need to allow cross site origin requests, so that our webbrowser can access the local node while connected with our webserver. By default webbrowsers do not allow script from one origin (our website) to access data from another origin (our node). 
* **--genesis** : json.file that defines the very first block in our private blockchain that everybody has to agree on

```
{
	"nonce": "0x123456789",
	"timestamp": "0x0",
	"parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"extraData": "0x0",
	"gasLimit": "0x800000000",
	"difficulty": "0x400",
	"mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"coinbase": "0x3333333333333333333333333333333333333333",
}
```

## 3. How to connect your web application to the local Node (using nodejs + express)

#####3.1 set up a simple nodejs server 

    npm init
    npm install express
    mkdir public
    touch myApp.js
    
##### myApp.js: 

    var express = require('express');

    var app = express();

    app.use(express.static('public'));  // files in directory 'public' get sent to client automatically

    var server = app.listen(8081, function () {

     var host = server.address().address
    var port = server.address().port

    console.log("App listening at http://%s:%s", host, port)

    })

#####3.2 Get web3.js library (easy way to access geth's RPC interface from a js app) 
Download [here](https://github.com/ethereum/web3.js/) or use `npm install web3`. Copy web3 folder to directory 'public'. 
    
#####3.3 Create html file in directory 'public'

```html
<!DOCTYPE html>
<html>
  <head>
    <script type="text/javascript" src="web3/dist/web3.js"> 
web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8454"));
</script>
  </head>
  <body>
    <h1>My first Decentralised Application</h1>
    web3.version.node;
  </body>
</html>
```

## 4. How to deploy contracts 

## 5. How to interact with contracts 

## 6. How to connect nodes to your private blockchain

## 7. How to connect your private chain to the Online Solidity Compiler 

[This](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js) solidity online compiler is a quite useful tool to test your contracts. 

#####7.1 Set up Node
We need to add the online compiler to our list of servers, that are allowed to interact with our node  despite the same origin policy.

    geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081,http://ethereum.github.io" --datadir "/home/mgsgde/privateEthereum" --genesis "/home/mgsgde/privateEthereum/CustomGenesis.json" console

(Make sure to access the online compiler via **http** protocol and not via https protocol.)

#####7.2 Set Endpoint
In the menu you can choose the "Web3 Provider" as execution environment. As enpoint type in the rpcaddress and rpc port from our node

    http://localhost:8454

## 8. How to connect your private chain to the Mist Wallet 





