# Ethereum Guide - (Example: Decentralised Stock Exchange)

## Install GETH

    sudo apt-get install software-properties-common
    sudo add-apt-repository -y ppa:ethereum/ethereum
    sudo apt-get update
    sudo apt-get install ethereum
    
GETH is the command line interface to run your node. Apart from interacting via command line, it also provides an interactive console and a JSON-RPC Server 

* start console
   '''geth console'''
* access Node from Browser
    geth --rpc --rpccorsdomain "<<your webserver address>> 









## 1. How to set up an Ethereum Node on a private Blockchain



geth --port 30303 --rpc --rpcport 8454 --rpccorsdomain "http://0.0.0.0:8081" --datadir "/home/mgsgde/privateEthereum"
--genesis "/home/mgsgde/privateEthereum/CustomGenesis.json"  console

* rpc : erlaubt remote precedure calls (ohne kannst du von deiner Website aus nicht auf deinen node zugreifen)

* rpcport : gibt den port an unter dem du deinen lokalen node von deiner Website aus finden kannst.

* Rpccorsdomain : die Domain zeigt auf meinen nodejs Server. Webbrowser verhindern scheinbar sogenannte cross site origin requests, sprich es ist unserer Website standardmäßig verboten sich mit unserem node zu verbinden.

* Genesis : json file, quasi der Anfangsblock deiner chain. Dort kannst du auch gleich deine accounts reichlich ether als Startkapital mitgeben. 

* --ipcpath /home/mgsgde/.ethereum/geth.ipc : hatte ich glaub drinne um meine private chain mit dem mist wallet zu verbinden, brauchst du aber nicht.

Wenn du nun zusätzliche nodes verbinden möchtest, dann musst eigt nur einen anderen pfad beim geth start command angeben und das gleiche Genesis.json file reinkopieren. Ports müsstest du natürlich auch andere verwenden.

Das sollte ich mal ordentlich und verständlich runterschreiben 😃  

WEBSITE: 
<script type="text/javascript" src="scripts//web3/dist/web3.js"> 
web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider("http://localhost:8454"));
</script> 

## 2. How to connect your webbrowser to your Node

## 3. How to deploy contracts 

## 4. How to interact with contracts 

## 5. How to connect nodes to your private blockchain



