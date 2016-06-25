

   contract DataFeed {


     bytes32 reqID;
     address sender;


     event askForPriceEvent(bytes32 id, bytes32 symbol);

     function askForPrice(address id, bytes32 symbol) returns (bytes32 result){
     // hier überprüfen ob id schon vorhanden und ob gas für alle weiteren operationen ausreicht
     reqID = sha256(now);
     sender = msg.sender;
     askForPriceEvent(reqID, symbol);
     return reqID;
     }

     // bei calls müssen die parameter im storage sein sowie die address auch this als addresse als parameter funktioniert nicht
     function sendPrice(bytes32 reqID, uint256 price) {
       sender.call(bytes4(sha3("__callback(bytes32,uint256)")),reqID,price);
     }
   }


   contract Token {

       // hier muss noch nen modifier hin der demokratisch verändert werden kann

       mapping (address =>uint256) public dollarBalanceOf;

       mapping (bytes32 => mapping (address =>uint256)) public stockDeposit;


       bytes32 priceRequestId;

       DataFeed public feed; // ich kann die variable nicht ohen funktion setzen
       function setFeed(address addr) {
       feed = DataFeed(addr);
       }


       mapping (bytes32 => Order) public orders;

       struct Order {
         bool isStockOrder;
         bool isBuyOrder;
         address id;
         bytes32 symbol;
         uint256 amount;
         uint256 price;
       }


       event BuyStockEventAmount(address id, uint256 amount, bytes32 symbol);
       event BuyStockEventPrice(address id, uint256 price, bytes32 symbol);
       event SellStockEvent(address id, uint256 amount, bytes32 symbol);

       event BuyDollarEvent(address id, uint256 price, uint256 amount);
       event SellDollarEvent(address id, uint256 price, uint256 amount);


       event stockInfo(address id, uint256 amount, bytes32 symbol);


   }

   contract DollarToken is Token {


   // prüfen ob symbol als währung definiert wurde todo!!
       function buyDollarTokens(){
         priceRequestId = feed.askForPrice.gas(4000000)(msg.sender,"ETHUSD");
         orders[priceRequestId].isStockOrder = false;
         orders[priceRequestId].isBuyOrder = true;
         orders[priceRequestId].id = msg.sender;
         orders[priceRequestId].symbol = "ETHUSD";
         orders[priceRequestId].amount = msg.value;
         orders[priceRequestId].price = 0;
       }

       function sellDollarTokens( uint256 amountToSell){ // in penny
         priceRequestId = feed.askForPrice.gas(4000000)(msg.sender,"ETHUSD");
         orders[priceRequestId].isStockOrder = false;
         orders[priceRequestId].isBuyOrder = false;
         orders[priceRequestId].id = msg.sender;
         orders[priceRequestId].symbol = "ETHUSD";
         orders[priceRequestId].amount = amountToSell;
         orders[priceRequestId].price = 0;
       }

       uint256 public toRefund;
       uint256 public amount;

       function __callbackDollar(bytes32 reqID, uint256 price) {  // dollar in einheit penny umrechnen
           orders[reqID].price = price;
           if (orders[reqID].isBuyOrder){
           amount = (orders[reqID].amount * orders[reqID].price)/1000000000000000000;
           dollarBalanceOf[orders[reqID].id] += amount;
           BuyDollarEvent(orders[reqID].id, orders[reqID].price, amount);
           } else {
           if (dollarBalanceOf[orders[reqID].id] < orders[reqID].amount  ) throw;
           dollarBalanceOf[orders[reqID].id] -= orders[reqID].amount;
           toRefund = ((orders[reqID].amount * 1000000000000000000) / orders[reqID].price);
           orders[reqID].id.send(toRefund);
           SellDollarEvent(orders[reqID].id, orders[reqID].price, orders[reqID].amount);
         }
      }
   }


   contract StockToken is Token {


       function buyStockTokens(bytes32 symbol, uint256 toBuy){
         priceRequestId = feed.askForPrice.gas(4000000)(msg.sender,symbol);
         orders[priceRequestId].isBuyOrder = true;
         orders[priceRequestId].isStockOrder = true;
         orders[priceRequestId].id = msg.sender;
         orders[priceRequestId].symbol = symbol;
         orders[priceRequestId].amount = toBuy;
         orders[priceRequestId].price = 0;
       }

       function sellStockTokens(bytes32 symbol, uint256 amountToSell){
         priceRequestId = feed.askForPrice.gas(4000000)(msg.sender,symbol);
         orders[priceRequestId].isBuyOrder = false;
         orders[priceRequestId].isStockOrder = true;
         orders[priceRequestId].id = msg.sender;
         orders[priceRequestId].symbol = symbol;
         orders[priceRequestId].amount = amountToSell;
         orders[priceRequestId].price = 0;
       }


       uint256 public cost;
       function __callbackStock(bytes32 reqID, uint256 price) {
       orders[reqID].price = price;

       if (orders[reqID].isBuyOrder){
               cost = orders[reqID].amount * orders[reqID].price;
               if (cost > dollarBalanceOf[orders[reqID].id]) throw;
               dollarBalanceOf[orders[reqID].id] -= cost;
               stockDeposit[orders[reqID].symbol][orders[reqID].id] += orders[reqID].amount;
               stockDeposit[orders[reqID].symbol][this] -= orders[reqID].amount;
               BuyStockEventAmount(orders[reqID].id, orders[reqID].amount, orders[reqID].symbol);
               BuyStockEventPrice(orders[reqID].id, orders[reqID].price, orders[reqID].symbol);
           } else {
               if (stockDeposit[orders[reqID].symbol][orders[reqID].id] < orders[reqID].amount  ) throw;
               stockDeposit[orders[reqID].symbol][orders[reqID].id] -= orders[reqID].amount;
               cost = orders[reqID].amount * orders[reqID].price;
               dollarBalanceOf[orders[reqID].id] += cost;
               SellStockEvent(orders[reqID].id, orders[reqID].amount,orders[reqID].symbol);
           }
      }

   }

   contract DSX is StockToken, DollarToken {


     function __callback(bytes32 reqID, uint256 price) {
       if (orders[reqID].isStockOrder) {
         __callbackStock(reqID,price);
       } else {
         __callbackDollar(reqID,price);
       }
     }

     function DSX() {
           dollarBalanceOf[this] = 100000000;
           dollarBalanceOf[msg.sender] = 500000000;
       }

       // ausbauen zu getReceipt mapping address symbol array und for schleife
       function getStockBalance(address id,bytes32 symbol) returns (uint256 result){
        result = stockDeposit[symbol][id];
        stockInfo(id, result, symbol);
        return result;
      }
   }
