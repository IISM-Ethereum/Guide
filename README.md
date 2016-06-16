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

    miner.start(1); admin.sleepBlocks(1); miner.stop();
    contractaddress = eth.getTransactionReceipt(txhash).contractAddress;
    eth.getCode(contractaddress);

    multiply7 = eth.contract(contract.info.abiDefinition).at(contractaddress);
    fortytwo = multiply7.multiply.call(6);

```

*Note: with js you can access all those functions via web3.js library.  Thus except for appending web3 in front of each command nothing changes.*

#####4.3 Compile via Online Solidity Compiler (Recommended) 

Go to the [Online Solidity Compiler](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js), write down your smart contracts and simply execute the content of the field "Web3 deploy" in the geth console. 

## 5. How to connect your private chain to the Online Solidity Compiler 

The [Online Compiler](http://ethereum.github.io/browser-solidity/#version=soljson-latest.js) provides the possiblity to create and test contracts directly on your private blockchain. 

#####5.1 Set up Node
We need to add the online compiler to our list of servers, that are allowed to interact with our node  despite the same origin policy.

    geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081,http://ethereum.github.io" --datadir "/home/mgsgde/privateEthereum" --genesis "/home/mgsgde/privateEthereum/CustomGenesis.json" console

(Make sure to access the online compiler via **http** protocol and not via https protocol.)

#####5.2 Set Endpoint
In the menu you can choose the "Web3 Provider" as execution environment. As endpoint type in the rpc-address and rpc-port from our node

    http://localhost:8454


## 6. How to interact with contracts from a different node

#####6.1 Get required information about conract on node where it was created: 

    multiply.address;
    mutliply.abi;

#####6.2 Different Node: 

    multiply7 = eth.contract(<<abi>>).at(<<address>>);
    fortytwo = multiply7.multiply.sendTransaction(6, { from: <<your account address>> });
    // alternatively assuming eth.defaultAccount is set 
    fortytwo = multiply7.muliply(6);

## 7. How to connect nodes to your private blockchain
Simply use the **same gensis block** and the **same network id**. 
*(Since we are on the same machine, we need to change the port and the datadir)*

#####7.1 First Node: 

    geth --port 30307 --datadir "/home/mgsgde/privateEthereum1" --genesis "/home/mgsgde/privateEthereum1/CustomGenesis.json" --networkid 27 console
    
#####7.2 Second Node:

    geth --port 30304 --datadir "/home/mgsgde/privateEthereum2" --genesis "/home/mgsgde/privateEthereum2/CustomGenesis.json" --networkid 27 console

#####7.3 In order to get our network initally going we need to define bootstrap nodes. This can be any existing node in our network. In our case the first node would serve as bootstrap for the second node. 

Retrieve the enode address with the following command:

    admin.nodeInfo.enode
   
Set bootnodes via command line

    geth --bootnodes "enode://pubkey1@ip1:port1 enode://pubkey2@ip2:port2 enode://pubkey3@ip3:port3"
    
or via geth console

    admin.addPeer("enode://pubkey1@ip1:port1")

## 8. How to connect your private chain to the Mist Wallet 
When a node is started, geth produces an ipc file in the nodes datadir. By default the Mist wallet is looking for this ipc file in the main ethereum folder ~/.ethereum/ . Consenquently we have to define the very same directory for our test network, so that the file gets produced in the dir where Mist is looking for it. 

    geth --datadir "/home/mgsgde/privateEthereum" --genesis "/home/mgsgde/privateEthereum/CustomGenesis.json" --ipcpath /home/mgsgde/.ethereum/geth.ipc --networkid 27 console




