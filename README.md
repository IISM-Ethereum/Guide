# Ethereum Guide

#### This guide aims to get interested people quickly set up to develop smart contracts on a private blockchain. All necessary packages/tools are reflected in this guide, so at the end one should be able to start right away with the development process.

At the time of writing there are three main ethereum implementations available: GETH (GO), Eth (C++) and Pyethapp. We're focussing on Geth, since it's the recommended choice if one plans to develop a corresponding frontend for a distributed database (the blockchain in our case), so-called dapps (decentralized apps).

Supported platforms: **Linux, MacOS**

## 1. GETH
#####1.1 Install
#### Linux
    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install ethereum

#### MacOS
Install Homebrew if you haven't done yet, further information to be found [here](http://brew.sh/).

    sudo brew update
    sudo brew upgrade
    sudo brew tap ethereum/ethereum
    sudo brew install ethereum

GETH is the command line interface to run your node. Apart from interacting via command line, it also provides an interactive console and a JSON-RPC Server.  

#####1.2 Start node and interact via built-in console:

    geth console

#####1.3 Start node and interact via JSON-RPC api from your browser:

    geth --rpc --rpccorsdomain "<<your webserver address>>"


## 2. How to set up an Ethereum Node on a private Blockchain

#####2.1 Full start command for node

#### Linux
```	
	geth --datadir "/home/USER/privateEthereum/CustomGenesis.json" init
    
	geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/home/USER/privateEthereum" console
   ``` 
   
**Note:** the option --genesis is deprecated and does not work anymore
```	    
	geth --datadir "/home/USER/privateEthereum/CustomGenesis.json" init
    
	geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/home/USER/privateEthereum" console
```
#### MacOS
    geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/Users/USER/privateEthereum"
    --genesis "/Users/USER/privateEthereum/CustomGenesis.json" console

#####2.2 Detailed information about the command above
* **--rpc** : Enables remote procedure calls (so that our website can interact with the node). The default APIs enabled are: "eth,net,web3".

* **--rpcapi**: Specify APIs to be enabled via HTTP-RPC, i.e. "eth,net,web3,admin,miner". **Note:** It's considered highly insecure to enable "personal" over RPC, since any user connecting to your node could brute-force the accounts in order to steal ether.

* **--rpcport** : Port that is used by the Web-Browser to interact with the local node.

* **--rpccorsdomain** : We need to allow cross site origin requests, so that our Web-browser can access the local node while being connected with our Web-Server. By default Web-Browsers do not allow scripts being retrieved from one origin (our webserver) to access data from another origin (our node). There's the possiblity to use a wildcard operator to allow all cross-origin connections (*), which is less secure but more convenient.
* **--datadir** : An arbitrary path in the user directory where the blockchain should be synchronized to.

* **--genesis** : json.file that defines the very first block in our private blockchain that everybody has to agree on.

In our case, the Genesis file is located in the same directory where the blockchain data will be located once the setup is completed.

A sample Genesis file looks as follows. In this example two accounts with a balance of one billion ether have been created during initialization.

```
{
	"nonce": "0x1779246622",
	"timestamp": "0x0",
	"parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"extraData": "0x0",
	"gasLimit": "0x800000000",
	"difficulty": "0x400",
	"mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"coinbase": "0x3333333333333333333333333333333333333333",
	"alloc": {
"d26dc93479a21f14fgd8cf65dda113c781b2a8c9": { "balance": "1000000000000000000000000000000" },
"0xf8f0abbc343dbb56er230bded3f7ae3c64322e0e" :{ "balance": "1000000000000000000000000000000" }
	}
}

```

Connecting to the node via RPC is great for development purposes, but the preferred way of securely interacting with the node is ipc, where all necessary APIs are enabled by default: "admin,db,eth,debug,miner,net,shh,txpool,personal,web3".
However, ipc connections are currently not supported by the web3.js library (there's a fork which is under heavy development), so we'll stick to RPC for now.

## 3. How to connect your web application to the local Node (using NodeJS + express)

#####3.1 set up a simple NodeJS server

Create a directory somewhere and then run the following commands.

    npm init
    npm install express
    mkdir public
    touch myApp.js

##### myApp.js:

    var express = require('express');

    var app = express();

    app.use(express.static('public'));  // files in directory 'public' get sent to client's webbrowser automatically

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

#####4.1 Install Solidiy Compiler solc

    npm install solc

You can check the installation in the interactive console via

    eth.getCompilers()

If it does not return ["Solidity"], then set the path manually interactive console via

    `admin.setSolc("<<path to the solc executable>>");`

#####4.2 Compile test contract in interactive console
 ```
    source = "contract test {\n" +
    "   /// @notice will multiply `a` by 7.\n" +
    "   function multiply(uint a) returns(uint d) {\n" +
    "      return a * 7;\n" +
    "   }\n" +
    "} ";
    contract = eth.compile.solidity(source).test;
    txhash = eth.sendTransaction({from: primary, data: contract.code});

    miner.start(); admin.sleepBlocks(1); miner.stop();
    contractaddress = eth.getTransactionReceipt(txhash).contractAddress;
    eth.getCode(contractaddress);

    multiply7 = eth.contract(contract.info.abiDefinition).at(contractaddress);
    fortytwo = multiply7.multiply.call(6);

```

*Note: with js you can access all those functions via web3.js library. Thus except for appending "web3.eth." to the beginning of each command nothing changes (e.g. "web3.eth.miner.start()") *

#####4.3 Compile via Online Solidity Compiler (Recommended)

Go to the [Online Solidity Compiler](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js), write down your smart contracts and simply execute the content of the field "Web3 deploy" in the geth console.

## 5. How to connect your private chain to the Online Solidity Compiler

The [Online Compiler](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js) provides the possiblity to create and test contracts directly on your private blockchain.

#####5.1 Set up Node
We need to add the online compiler to our list of servers, that are allowed to interact with our node  despite the same origin policy.

    geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081,http://ethereum.github.io" --datadir "/home/USER/privateEthereum" console

(Make sure to access the online compiler via **http** protocol and not via https protocol.)

#####5.2 Set Endpoint
In the menu you can choose the "Web3 Provider" as execution environment. As endpoint type in the rpc-address and rpc-port from our node

    http://localhost:8454


## 6. How to interact with contracts from a different node

#####6.1 Get all the defining information about the contract: (if the contract was created by yourself, retrieve the info as shown below)

    multiply.address;
    mutliply.abi;	// interface description

#####6.2 Start different Node and find contract "multiply":

    multiply7 = eth.contract(<<abi>>).at(<<address>>);
    fortytwo = multiply7.multiply.sendTransaction(6, { from: <<your account address>> });
    // alternatively assuming eth.defaultAccount is set
    fortytwo = multiply7.muliply(6);

## 7. How to connect nodes to your private blockchain
Simply use the **same gensis block** and the **same network id**.
*(Since for test purposes you might want to run two nodes on the very same machine, simply change the port and the datadir)*

#####7.1 First Node:

    geth --port 30307 --datadir "/home/USER/privateEthereum1" --networkid 27 console

#####7.2 Second Node:

    geth --port 30304 --datadir "/home/USER/privateEthereum2" --networkid 27 console

Make sure to initialize again the very same custom genesis block as described in chapter 2, otherwise you will be on the main chain. 

#####7.3 In order to get our network initally going we need to define bootstrap nodes. This can be any existing node in our network. In our case the first node would serve as bootstrap for the second node.

Retrieve the enode address with the following command:

    admin.nodeInfo.enode

Set bootnode via geth console

    admin.addPeer("enode://pubkey1@ip1:port1")

If there is an error, saying that the chain is broken, delete all chain data in both projects and run it again.

Check if it has worked by listing all peers via: 

    admin.peers()
  

## 8. How to connect your private chain to the Mist Wallet
When a node is started, geth produces an ipc file in the node's datadir. By default the Mist wallet is looking for this ipc file in the main ethereum folder ~/.ethereum/ . Consenquently we have to define the very same directory for our test network, so that the file gets produced in the dir where Mist is looking for it.

    geth --datadir "/home/USER/privateEthereum" --ipcpath /home/USER/.ethereum/geth.ipc --networkid 27 console
    
## 9. Useful links / Sources 

[Online Compiler](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js)

[Solidity Documentation](https://media.readthedocs.org/pdf/solidity/latest/solidity.pdf) 

[JS Api: App Development](https://github.com/ethereum/wiki/wiki/JavaScript-API)

[JS Api: all functionality](https://github.com/ethereum/go-ethereum/wiki/JavaScript-Console)

[Management of Contracts and Transactions](https://github.com/ethereum/go-ethereum/wiki/Contracts-and-Transactions)

[Setting up your private Network](https://github.com/ethereum/go-ethereum/wiki/Connecting-to-the-network)

[Token Standard](https://github.com/ethereum/EIPs/issues/20)

### Authors
Magnus Gödde (@mgsgde)  
Jonas-Taha El Sesiy (@elsesiy)
