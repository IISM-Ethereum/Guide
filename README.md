# Ethereum Guide

## 1. GETH
#### install
    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install ethereum
    
GETH is the command line interface to run your node. Apart from interacting via command line, it also provides an interactive console and a JSON-RPC Server.  

##### interactive console:

    geth console

##### access node via JSON-RPC api from browser:

    geth --rpc --rpccorsdomain "<<your webserver address>> 


## 2. How to set up an Ethereum Node on a private Blockchain

#### start node
geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/home/mgsgde/privateEthereum"
--genesis "/home/mgsgde/privateEthereum/CustomGenesis.json" console

* --rpc : enables rpc (so that our website can interact with the node) 

* --rpcport : port that is used by the webbrowser to interact with the local node

* --rpccorsdomain : we need to allow cross site origin requests, so that our webbrowser can access the local node while connected with our webserver. By default webbrowsers do not allow script from one origin (our website) to access data from another origin (our node). 
* --genesis : json.file that defines the very first block in our prive blockchain that everybody has to agree on


WEBSITE: 
<script type="text/javascript" src="scripts//web3/dist/web3.js"> 
web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8454"));
</script> 

## 2. How to connect your webbrowser to your Node

## 3. How to deploy contracts 

## 4. How to interact with contracts 

## 5. How to connect nodes to your private blockchain

## 6. How to connect your private chain to the official Mist Wallet



