

  contract Etherex {
      Market[] markets;

      struct Market{
        uint256 id;
        bytes32 name;
        address con;
        uint256 decimals;
        uint256 precision;
        uint256 minimum;
        uint256 category;
        uint256 last_price;
        address owner;
        uint256 block;
        uint256 total_trades;
        bytes32 last_trade;

        bytes32 lowest_ask_id;
        mapping (bytes32 => Trade_id) ask_orderbook;

        bytes32 highest_bid_id;
        mapping (bytes32 => Trade_id) bid_orderbook;

      }
      struct Trade_id{
        bytes32 id;
        bytes32 next_id;
        bytes32 prev_id;
      }
      struct Trade {
        bytes32 typ;
        uint256 amount;
        uint256 price;
        uint256 market_id;
        bytes32 id;
        address sender;
        address owner;
        uint256 blockNumber;
      }
      struct BalanceSt {
        uint256 available;
        uint256 trading;
      }

      mapping (bytes32 => Trade) trades;
      mapping (address => mapping (uint256 => BalanceSt)) balances;
      mapping (bytes32 => uint256) markets_name;
      mapping (address => uint256) markets_id;

      uint256 public last_market = 0;

      uint256 _id;


      Token public token;
      // todo parameter
      // todo auf standard prüfen ?!
        function test_add_market(address addr) returns (uint256 rv){


          _id = last_market + 1;

          //if (name <= 0) throw;
         // if (markets_name[name] != 0) throw;
          //if (con == 0) throw;
         // if (category < 0 || precision < 0 || minimum < 0) throw;


            Market storage m;
            m.id = _id;
            m.name = "name";
            m.con = addr;

            m.last_price = 1;
            m.lowest_ask_id = 0;
            m.owner = msg.sender;
            m.block = block.number;
            markets.push(m);

            last_market = _id;
              settoken(addr);
            return _id;
        }


    address public testaddress = this;

    function settoken(address addr){
      token = Token(addr);
    }

    function transferFrom() returns (uint256 rv){
      token.transferFrom(msg.sender, this, 10);
      return token.balanceOf(this);
    }

  // überträgt tokens von deiner addresse zu diesem contract der diese dann in balances mapping speichert. damit kann dann getraded weren
      function deposit() returns (uint256 rv){  // parameter fesdtelgen
          uint256  amount = 10;
          uint256  market_id = 1;


          if (token.transferFrom(msg.sender, this, amount)){
            uint256 balance = balances[msg.sender][market_id].available;
            balance = balance + amount;
            balances[msg.sender][market_id].available = balance;
            return token.balanceOf(this);
          }
      }

  function check_trade(uint256 amount, uint256 price, uint256 market_id) returns (bool rv){
    if (amount <= 0 || price <=0 || market_id <=0) return false;
    return true;
  }

  function buy(uint256 amount, uint256 price, uint256 market_id) returns(uint256 rv) {
    if (!check_trade(amount, price, market_id)) throw;

    uint256 value = (amount*price) * 1000000000000000000;


    if (msg.value < value) throw;
    if (msg.value > value){
      msg.sender.send(msg.value - value);
    }

    test_save_trade("BID",amount,price,market_id);
    return value;
  } // am ende von buy die trade funktion ausführen TODO

  function sell(uint256 amount, uint256 price, uint256 market_id){
    if (!check_trade(amount, price, market_id)) throw;

    uint256 balance = balances[msg.sender][market_id].available;
    if (balance > amount){
      test_save_trade("ASK",amount,price,market_id);
    }
  }  // am ende von sell die trade funktion aushüren TODO

  function min(uint a, uint b) returns (uint) {
      if (a < b) return a;
      else return b;
  }

  // ################################# test part ###################################################
  // ###############################################################################################

  bytes32 public prev;
  bytes32 public id;
  bytes32 public next;
  event EventIds(bytes32 prev,bytes32 id,bytes32 next);
  event EventPrices(uint256 prev,uint256 id,uint256 next);

  // umbennen TODO
  function test_save_trade(bytes32 _typ,uint256 _amount, uint256 _price, uint256 _market_id) returns(bytes32 rv){
   // inititialisieren zwecks test
   bytes32 typ = _typ;
   uint256 amount = _amount;
   uint256 market_id = _market_id;
   uint256 price = _price;
   // end initilialisieren

   bytes32 trade_id = sha3(typ,amount,price,market_id,msg.sender,block.number);

   if (trades[trade_id].id != 0) throw;

     trades[trade_id].typ = typ;
     trades[trade_id].amount = amount;
     trades[trade_id].price = price;
     trades[trade_id].market_id = market_id;
     trades[trade_id].sender = msg.sender;
     trades[trade_id].blockNumber = block.number;
     trades[trade_id].id = trade_id;


     bool positionFound = false;
     bytes32 id_iter;
     if (typ == "ASK"){
       bytes32 lowest_ask_id = markets[market_id].lowest_ask_id;
       markets[market_id].ask_orderbook[trade_id].id = trade_id;
       if (trades[lowest_ask_id].price == 0 || price < trades[lowest_ask_id].price){     // fälle wo ask ganz vorne dran gehangen wird
         if (trades[lowest_ask_id].price == 0) {
           markets[market_id].lowest_ask_id  = trade_id;
         } else {
           markets[market_id].ask_orderbook[trade_id].next_id = markets[market_id].lowest_ask_id ;
           markets[market_id].lowest_ask_id = trade_id;
         }
       } else {
          id_iter = lowest_ask_id;
         while (!positionFound){ // ask wird iwo zwischen gesetzt
           if (price < trades[markets[market_id].ask_orderbook[id_iter].next_id].price) {
             markets[market_id].ask_orderbook[trade_id].next_id = markets[market_id].ask_orderbook[id_iter].next_id;
             markets[market_id].ask_orderbook[trade_id].prev_id = id_iter;
             markets[market_id].ask_orderbook[markets[market_id].ask_orderbook[id_iter].next_id].prev_id = trade_id;
             markets[market_id].ask_orderbook[id_iter].next_id = trade_id;
             positionFound = true;
           }
           if (markets[market_id].ask_orderbook[id_iter].next_id == 0){ // ask wird ganz hinten dran gehangen
             markets[market_id].ask_orderbook[trade_id].prev_id = id_iter;
             markets[market_id].ask_orderbook[id_iter].next_id = trade_id;
             positionFound = true;
           }
           id_iter = markets[market_id].ask_orderbook[id_iter].next_id;
           balances[msg.sender][market_id].available -= amount;
           balances[msg.sender][market_id].trading += amount;
         }
       }
     prev = markets[market_id].ask_orderbook[trade_id].prev_id;
     id = markets[market_id].ask_orderbook[trade_id].id;
     next = markets[market_id].ask_orderbook[trade_id].next_id;
     //EventIds(prev,id,next);
     //EventPrices(trades[prev].price, trades[id].price, trades[next].price);
     }

     if (typ == "BID"){
       bytes32 highest_bid_id = markets[market_id].highest_bid_id;
       markets[market_id].bid_orderbook[trade_id].id = trade_id;
       if (trades[highest_bid_id].price == 0 || price > trades[highest_bid_id].price){     // fälle wo bid ganz vorne dran gehangen wird
         if (trades[highest_bid_id].price == 0) {
           markets[market_id].highest_bid_id  = trade_id;
         } else {
           markets[market_id].bid_orderbook[trade_id].next_id = markets[market_id].highest_bid_id ;
           markets[market_id].highest_bid_id = trade_id;
         }
       } else {
          id_iter = highest_bid_id;
         while (!positionFound){ // bid wird iwo zwischen gesetzt
           if (price > trades[markets[market_id].bid_orderbook[id_iter].next_id].price) {
             markets[market_id].bid_orderbook[trade_id].next_id = markets[market_id].bid_orderbook[id_iter].next_id;
             markets[market_id].bid_orderbook[trade_id].prev_id = id_iter;
             markets[market_id].bid_orderbook[markets[market_id].bid_orderbook[id_iter].next_id].prev_id = trade_id;
             markets[market_id].bid_orderbook[id_iter].next_id = trade_id;
             positionFound = true;
           }
           if (markets[market_id].bid_orderbook[id_iter].next_id == 0){ // bid wird ganz hinten dran gehangen
             markets[market_id].bid_orderbook[trade_id].prev_id = id_iter;
             markets[market_id].bid_orderbook[id_iter].next_id = trade_id;
             positionFound = true;
           }
           id_iter = markets[market_id].bid_orderbook[id_iter].next_id;
           balances[msg.sender][market_id].available -= amount;
           balances[msg.sender][market_id].trading += amount;
         }
       }
     prev = markets[market_id].bid_orderbook[trade_id].prev_id;
     id = markets[market_id].bid_orderbook[trade_id].id;
     next = markets[market_id].bid_orderbook[trade_id].next_id;
     //EventIds(prev,id,next);
     //EventPrices(trades[prev].price, trades[id].price, trades[next].price);
     }

  }

  // umbennnen
  function test_remove_trade(bytes32 trade_id, uint256 market_id){

    bytes32 flag = "BID";


    if (trades[trade_id].typ == flag){

        if (markets[market_id].highest_bid_id == trade_id){
          markets[market_id].highest_bid_id = markets[market_id].bid_orderbook[trade_id].next_id;
          bytes32 highest = markets[market_id].highest_bid_id;

        }
    bytes32 prev_id = markets[market_id].bid_orderbook[trade_id].prev_id;
    bytes32 next_id = markets[market_id].bid_orderbook[trade_id].next_id;

    markets[market_id].bid_orderbook[prev_id].next_id = next_id;
    markets[market_id].bid_orderbook[next_id].prev_id = prev_id;

    markets[market_id].bid_orderbook[trade_id].id = 0;
    markets[market_id].bid_orderbook[trade_id].next_id = 0;
    markets[market_id].bid_orderbook[trade_id].prev_id = 0;
    } else {
      if (markets[market_id].lowest_ask_id == trade_id){
        markets[market_id].lowest_ask_id = markets[market_id].ask_orderbook[trade_id].next_id;
        bytes32 lowest = markets[market_id].highest_bid_id;

      }

      prev_id = markets[market_id].ask_orderbook[trade_id].prev_id;
      next_id = markets[market_id].ask_orderbook[trade_id].next_id;

      markets[market_id].ask_orderbook[prev_id].next_id = next_id;
      markets[market_id].ask_orderbook[next_id].prev_id = prev_id;

      markets[market_id].ask_orderbook[trade_id].id = 0;
      markets[market_id].ask_orderbook[trade_id].next_id = 0;
      markets[market_id].ask_orderbook[trade_id].prev_id = 0;
    }

    markets[market_id].total_trades -= 1;

    trades[trade_id].typ = 0;
    trades[trade_id].amount = 0;
    trades[trade_id].price = 0;
    trades[trade_id].market_id = 0;
    trades[trade_id].id = 0;
    trades[trade_id].sender = 0;
    trades[trade_id].blockNumber = 0;
  }

  function test(){
    balances[msg.sender][1].available = 50000;
    test_add_market(address(123));

    buy(1,4,1);
    buy(1,5,1);
    buy(1,1,1);
    sell(2,1,1);
    sell(1,2,1);
    sell(1,3,1);
    sell(1,4,1);
  }
  /* Im Moment wird nicht so viel wie möglich gematched sondern die hohen gebote werde zuerst bedient.
  Das könnte ich noch umprogrammieren, dass so viel wie möglich gematched wird und dann nach volumen
  verteil
  todo

  */
  event testEvent(bytes32 typ, uint256 price, uint256 amount);
  event testEvent1(bytes32 tradeid);

  function test_trade() {

    uint256 market_id = 1;

    bool bid_matched = false;
    bool ask_matched = false;
    bytes32 id_iter_bid = markets[market_id].highest_bid_id;
    bytes32 id_iter_ask = markets[market_id].lowest_ask_id;
    uint256 fill;
    uint256 payback;
    uint256 costs;

    bytes32 id_iter_ask_helper;
    bytes32 id_iter_bid_helper;
  // stopp hierer weiter arbeitne!!!!!!!!!!!!!!!!!!!!!!
    while(!bid_matched){
      bid_matched = true;
      //if (block.number <= trades[id_iter_bid].blockNumber) continue;  // in test umgebung raus lassen
      while(!ask_matched){
        ask_matched = true;
        //if (block.number <= trades[id_iter_ask].blockNumber) continue;  // in test umgebung funktioniert das noch nicht
        if (trades[id_iter_bid].price >= trades[id_iter_ask].price) {  // es wird mehr geboten als gefragt
          /*testEvent(trades[id_iter_bid].typ,trades[id_iter_bid].price,trades[id_iter_bid].amount);
          testEvent1(trades[id_iter_bid].id );
          testEvent(trades[id_iter_ask].typ,trades[id_iter_ask].price,trades[id_iter_ask].amount);
          testEvent1(trades[id_iter_ask].id  ); */

          bid_matched = false;
         if (trades[id_iter_bid].amount > trades[id_iter_ask].amount){
             fill =  trades[id_iter_ask].amount;
            trades[id_iter_bid].amount -= fill;
            balances[trades[id_iter_ask].owner][market_id].trading -= fill;
            balances[trades[id_iter_bid].owner][market_id].available += fill;
            costs = fill * trades[id_iter_ask].price * 1000000000000000000;
            payback = fill * (trades[id_iter_bid].price - trades[id_iter_ask].price) * 1000000000000000000;
            trades[id_iter_ask].owner.send(costs);
            if (payback > 0){
              trades[id_iter_bid].owner.send(payback);
            }
            id_iter_ask_helper = id_iter_ask;
            id_iter_ask = markets[market_id].ask_orderbook[id_iter_ask].next_id;
            //id_iter_bid = markets[market_id].bid_orderbook[id_iter_bid].next_id;
            test_remove_trade(id_iter_ask_helper,market_id);
            ask_matched = false;
          }
           if (trades[id_iter_bid].amount == trades[id_iter_ask].amount) {
            fill =  trades[id_iter_bid].amount;
            balances[trades[id_iter_ask].owner][market_id].trading -= fill;
            balances[trades[id_iter_bid].owner][market_id].available += fill;
            costs = fill * trades[id_iter_ask].price * 1000000000000000000;
            payback = fill * (trades[id_iter_bid].price - trades[id_iter_ask].price) * 1000000000000000000;
            trades[id_iter_ask].owner.send(costs);
            if (payback > 0){
              trades[id_iter_bid].owner.send(payback);
            }
            id_iter_ask_helper = id_iter_ask;
            id_iter_bid_helper = id_iter_bid;
            id_iter_ask = markets[market_id].ask_orderbook[id_iter_ask].next_id;
            id_iter_bid = markets[market_id].bid_orderbook[id_iter_bid].next_id;
            test_remove_trade(id_iter_ask_helper,market_id);
            test_remove_trade(id_iter_bid_helper,market_id);
          }
          if (trades[id_iter_bid].amount < trades[id_iter_ask].amount) {
            fill =  trades[id_iter_bid].amount;
            trades[id_iter_ask].amount -= fill;
            balances[trades[id_iter_ask].owner][market_id].trading -= fill;
            balances[trades[id_iter_bid].owner][market_id].available += fill;
            costs = fill * trades[id_iter_ask].price * 1000000000000000000;
            payback = fill * (trades[id_iter_bid].price - trades[id_iter_ask].price) * 1000000000000000000;
            trades[id_iter_ask].owner.send(costs);
            if (payback > 0){
              trades[id_iter_bid].owner.send(payback);
            }
            id_iter_bid_helper = id_iter_bid;
            //id_iter_ask = markets[market_id].ask_orderbook[id_iter_ask].next_id;
            id_iter_bid = markets[market_id].bid_orderbook[id_iter_bid].next_id;
            test_remove_trade(id_iter_bid_helper,market_id);
          }
        }
      } // end while loop for ask bids
      ask_matched = false;
    }
  }

  event orderBookEntry(bytes32 typ, uint256 price, uint256 amount);


  // ############################################# test 1906
  function test_show_orderbook()  {
    uint256 market_id = 1;
    bytes32 id_iter_bid = markets[market_id].highest_bid_id;

    while (trades[id_iter_bid].amount != 0){
      orderBookEntry(trades[id_iter_bid].typ, trades[id_iter_bid].price, trades[id_iter_bid].amount );
      id_iter_bid = markets[market_id].bid_orderbook[id_iter_bid].next_id;
    }

    bytes32 id_iter_ask = markets[market_id].lowest_ask_id;

    while (trades[id_iter_ask].amount != 0){
      orderBookEntry(trades[id_iter_ask].typ, trades[id_iter_ask].price, trades[id_iter_ask].amount );
      id_iter_ask = markets[market_id].ask_orderbook[id_iter_ask].next_id;
    }


    bytes32 highest = markets[market_id].highest_bid_id;
    bytes32 lowest = markets[market_id].lowest_ask_id;
  }

  function bytes32ToString (bytes32 data) constant internal returns (string) {
    bytes memory bytesString = new bytes(32);
    for (uint j=0; j<32; j++) {
        byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[j] = char;
        }
    }
    return string(bytesString);
}

  }



  contract Token {

    address public token = this;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

      function transfer(address _to, uint256 _value) returns (bool success) {
          //Default assumes totalSupply can't be over max (2^256 - 1).
          //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
          //Replace the if with this one instead.
          //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
          if (balances[msg.sender] >= _value && _value > 0) {
              balances[msg.sender] -= _value;
              balances[_to] += _value;
              Transfer(msg.sender, _to, _value);
              return true;
          } else { return false; }
      }

      function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
          //same as above. Replace this line with the following if you want to protect against wrapping uints.
          //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
          if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
              balances[_to] += _value;
              balances[_from] -= _value;
              allowed[_from][msg.sender] -= _value;
              //Transfer(_from, _to, _value);
              return true;
          } else { return false; }
      }

      function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
      }

      function approve(address _spender, uint256 _value) returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
      }

      function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
      }

      mapping (address => uint256) balances;
      mapping (address => mapping (address => uint256)) allowed;
      uint256 public totalSupply;


      function () {
          //if ether is sent to this address, send it back.
          throw;
      }

      /* Public variables of the token */

      /*
      NOTE:
      The following variables are OPTIONAL vanities. One does not have to include them.
      They allow one to customise the token contract & in no way influences the core functionality.
      Some wallets/interfaces might not even bother to look at this information.
      */
      string public name;                   //fancy name: eg Simon Bucks
      uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
      string public symbol;                 //An identifier: eg SBX
      string public version = 'H0.1';       //human 0.1 standard. Just an arbitrary versioning scheme.

      function Token() {
          balances[msg.sender] = 10000;               // Give the creator all initial tokens
          totalSupply = 10000;                        // Update total supply
      }

  }
