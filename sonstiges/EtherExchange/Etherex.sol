

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
  mapping (bytes32 => Trade_id) trade_ids;
  // um das mapping trade_ids iterieren zu können
  uint256 trade_ids_length;
  mapping (uint256 => bytes32) trade_ids_members;
  mapping (bytes32 => uint256) trade_ids_reverse;
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



event TradeEvent_sender_type(bytes32 trade_id, address sender, bytes32 typ);
event TradeEvent_price_amount(bytes32 trade_id, uint256 price, uint256 amount);
event DepositEvent(uint256 marketID, address sender, uint256 amount);
event DebugEvent(string);

// start functions

// kann ersetzt werden durch noether modifier
function refund(){
  if (msg.value > 0){
    msg.sender.send(msg.value);
  }
}

function check_trade(uint256 amount, uint256 price, uint256 market_id) returns (bool rv){
  if (amount <= 0 || price <=0 || market_id <=0) return false;
  return true;
}

 bytes32 last_id;
 Trade tr;
function save_trade(bytes32 typ, uint256 amount, uint256 price, uint256 market_id) returns (bytes32 rv){

   bytes32 trade_id = sha3(typ,amount,price,market_id,msg.sender,block.number);


   if (trades[trade_id].id == 0){
     trades[trade_id].typ = typ;
     trades[trade_id].amount = amount;
     trades[trade_id].price = price;
     trades[trade_id].market_id = market_id;
     trades[trade_id].sender = msg.sender;
     trades[trade_id].blockNumber = block.number;
     trades[trade_id].id = trade_id;

     last_id = markets[market_id].last_trade;

     markets[market_id].trade_ids[last_id].next_id = trade_id;
     markets[market_id].trade_ids[trade_id].prev_id = last_id;
     markets[market_id].trade_ids[trade_id].id = trade_id;

     // tracking the length
     markets[market_id].trade_ids_length += 1;

     markets[market_id].trade_ids_members[ markets[market_id].trade_ids_length] = trade_id;
     markets[market_id].trade_ids_reverse[trade_id] = markets[market_id].trade_ids_length;

     markets[market_id].last_trade = trade_id;
     markets[market_id].total_trades += 1;

     if (typ == "ASK"){
       balances[msg.sender][market_id].available -= amount;
       balances[msg.sender][market_id].trading += amount;
     }
   }

   TradeEvent_sender_type(trade_id, msg.sender, typ);
   TradeEvent_price_amount(trade_id, price, amount);
   return trade_id;
}

function remove_trade(bytes32 trade_id, uint256 market_id){
  trades[trade_id].typ = 0;
  trades[trade_id].amount = 0;
  trades[trade_id].price = 0;
  trades[trade_id].market_id = 0;
  trades[trade_id].id = 0;
  trades[trade_id].sender = 0;
  trades[trade_id].blockNumber = 0;

  bytes32 prev_id = markets[market_id].trade_ids[trade_id].prev_id;
  bytes32 next_id = markets[market_id].trade_ids[trade_id].next_id;

  markets[market_id].trade_ids[prev_id].next_id = next_id;
  markets[market_id].trade_ids[next_id].prev_id = prev_id;

  markets[market_id].trade_ids[trade_id].id = 0;
  markets[market_id].trade_ids[trade_id].next_id = 0;
  markets[market_id].trade_ids[trade_id].prev_id = 0;

  // tracking the length
  uint256 x = markets[market_id].trade_ids_reverse[trade_id];
  markets[market_id].trade_ids_reverse[trade_id] = 0;
  markets[market_id].trade_ids_members[x] = 0;
  markets[market_id].trade_ids_length -= 1;

  markets[market_id].total_trades -= 1;

}

function getPrice(uint256 market_id) returns (uint256 rv){
    // no ether modifier
    return markets[market_id].last_price;
}

function buy(uint256 amount, uint256 price, uint256 market_id) {
  if (!check_trade(amount, price, market_id)) throw;

  uint256 value = ((amount*price) / (markets[market_id].precision * 10 ^ markets[market_id].decimals)) * 10 ^ 18;


  if (msg.value < value) throw;
  if (msg.value > value){
    msg.sender.send(msg.value - value);
  }

  save_trade("BID",amount,price,market_id);
}


function sell(uint256 amount, uint256 price, uint256 market_id){
  if (!check_trade(amount, price, market_id)) throw;

  uint256 value = ((amount*price) / (markets[market_id].precision * 10 ^ markets[market_id].decimals)) * 10 ^ 18;
  if (msg.value < markets[market_id].minimum) throw;
  uint256 balance = balances[msg.sender][market_id].available;
  if (balance > amount){
    save_trade("ASK",amount,price,market_id);
  }
}


function test_deposit() returns(address rv){
  uint256 market_id = 1;
  uint256 amount = 10;
  address hier = this;
  address con = markets[market_id].con;
  return con;
}

function deposit(uint256 _amount, uint256 market_id){
  uint256 amount = _amount;
  address hier = this;
  address con = markets[market_id].con;
   con.call(bytes4(bytes32(sha3("transferFrom(address,address,uint256)"))), msg.sender, hier, amount);
    uint256 balance = balances[msg.sender][market_id].available;
    balance = balance + amount;
    balances[msg.sender][market_id].available = balance;
    //DepositEvent(market_id, msg.sender, amount);
}


function trade(uint256 max_amount, uint256 market_id) internal {
  uint256 max_value = msg.value;


  for (uint t=0; t<markets[market_id].trade_ids_length;t++){

    if (markets[market_id].trade_ids_members[t] == 0) continue;

    bytes32 trade_id = markets[market_id].trade_ids_members[t];

    if (block.number <= trades[trade_id].blockNumber) throw;

    // get market
    address con = markets[market_id].con;
    uint256 decimals = markets[market_id].decimals;
    uint256 precision = markets[market_id].precision;
    uint256 minimun = markets[market_id].minimum;

    // get trade
    bytes32 typ = trades[trade_id].typ;
    uint256 amount = trades[trade_id].amount;
    uint256 price = trades[trade_id].price;
    address owner = trades[trade_id].owner;

    uint256 value;

    if (typ == "BID"){

      uint256 balance = balances[msg.sender][market_id].available;

      if (balance > 0){
        uint256 fill = min(amount, min(balance, max_amount));

        value = ((fill * price) * 10 ^ 18) / (precision * 10 ^ decimals);

        // insufficient value preventention
        if (value < minimun){
          if (max_value>0){
            msg.sender.send(max_value);
          }
        }

        if (fill < amount){
          trades[trade_id].amount -= fill;
        } else {
          remove_trade(trade_id,market_id);
        }

        balances[msg.sender][market_id].available -= fill;
        balances[owner][market_id].available += fill;

        msg.sender.send(fill);
      }
    }
    if (typ == "ASK"){
      if (max_value < 0) throw;
      if (max_value < minimun){
        if (max_value>0){
          msg.sender.send(max_value);
        }
      }

      uint256 trade_value = ((amount * price) * 10 ^ 18) / (precision * 10 ^ decimals);

      value = min(max_value, trade_value);

      if(value < trade_value){
        fill = ((value * (precision * 10 ^ decimals)) / price) / 10 ^ 18;
        trades[trade_id].amount -= fill;
      } else {
        fill = amount;
        remove_trade(trade_id, market_id);
      }

      balances[owner][market_id].trading -= fill;
      balances[msg.sender][market_id].available += fill;

      owner.send(value);
    }

    markets[market_id].last_price = price;

    max_amount -= fill;
    max_value -= value;
  }

if (max_value > 0){
  msg.sender.send(max_value);
}

}

function min(uint a, uint b) returns (uint) {
    if (a < b) return a;
    else return b;
}

function withdraw(uint256 amount,uint256 market_id){
  uint256 balance = balances[msg.sender][market_id].available;
  if (balance >= amount) {
    balances[msg.sender][market_id].available = balance - amount;
    address con = markets[market_id].con;
    con.call(bytes4(bytes32(sha3("transfer(address,uint256)"))), msg.sender, amount);
  }
}


function cancel(bytes32 trade_id){

  // get market
  uint256 market_id = trades[trade_id].market_id;
  address con = markets[market_id].con;
  uint256 decimals = markets[market_id].decimals;
  uint256 precision = markets[market_id].precision;

  // get trade
  bytes32 typ = trades[trade_id].typ;
  uint256 amount = trades[trade_id].amount;
  uint256 price = trades[trade_id].price;
  address owner = trades[trade_id].owner;

  if (msg.sender == owner) {

    remove_trade(trade_id, market_id);


    if (typ == "BID") {
      uint256 value = ((amount * price) / (precision * 10 ^ decimals)) * 10 ^ 18;
      msg.sender.send(value);
    }

    if (typ == "ASK") {
      balances[msg.sender][market_id].trading -= amount;
      balances[msg.sender][market_id].available += amount;
    }

  }
}


function test_call(address addr){
    address sender = addr;
    uint256 price = 5;
    sender.call(bytes4(sha3("__callback(uint256)")),5);
}


function test_MarketCreation(){
    Market m;
     m.id = 7;
    m.name = "name";
    markets[0] = m;


}

function test_getMarket() returns(bytes32 rv){
    return markets[0].name;
}
function test_getMarket1() returns(bytes32 rv){
    return markets[1].name;
}


uint256 _id;
function test_add_market(address addr) returns (uint256 rv){

   bytes32 name = "test_name1";
   uint256 decimals = 2;
   uint256 precision = 2;
   uint256 minimum = 2;
   uint256 category = 1;

  address con = addr;
  _id = last_market + 1;

  if (name <= 0) throw;
  if (markets_name[name] != 0) throw;
  if (con == 0) throw;
  if (category < 0 || precision < 0 || minimum < 0) throw;


     // Check Standard Token support
    address hier = this;
    con.call(bytes4(bytes32(sha3("approve(address,uint256)"))), hier, 0);


    Market storage m;
    m.id = _id;
    m.name = name;
    m.con = con;
    m.category = category;
    m.decimals = decimals;
    m.precision = precision;
    m.minimum = minimum;
    m.last_price = 1;
    m.owner = msg.sender;
    m.block = block.number;
    markets.push(m);

    markets_id[con] = _id;
    markets_name[name] = _id;
    last_market = _id;
    return _id;

}

function add_market(bytes32 name, address addr, uint256 decimals, uint256 precision, uint256 minimum, uint256 category){

  address con = addr;
  uint256 id = last_market + 1;

  if (name <= 0) throw;
  if (markets_name[name] != 0) throw;
  if (con == 0) throw;
  if (category < 0 || precision < 0 || minimum < 0) throw;



    Market memory m;
    m.id = id;
    m.name = name;
    m.con = con;
    m.category = category;
    m.decimals = decimals;
    m.precision = precision;
    m.minimum = minimum;
    m.last_price = 1;
    m.owner = msg.sender;
    m.block = block.number;
    // markets.push(m); push funktioniert nicht mit komplexen datentypen
    markets[id] = m;

    markets_id[con] = id;
    markets_name[name] = id;
    last_market = id;
}

function get_market_id(address addr) returns (uint256 rv){
  return markets_id[addr];
}
function get_market_id_by_name(bytes32 name) returns (uint256 rv){
  return markets_name[name];
}
function get_last_market_id() returns (uint256 rv){
  return last_market;
}

function get_sub_balance(address addr, uint256 market_id) returns (uint256 available){
  return balances[addr][market_id].available;
}
}


contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            //Transfer(msg.sender, _to, _value);
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
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }



    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


contract HumanStandardToken is StandardToken {

   // function () {
        //if ether is sent to this address, send it back.
     //   throw;
    //}

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





    uint256 public x;
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        //Approval(msg.sender, _spender, _value);
        x=5;
        return true;
    }

    function HumanStandardToken() {
        balances[msg.sender] = 100000;               // Give the creator all initial tokens
        totalSupply = 100000;                        // Update total supply
        name = "token";                                   // Set the name for display purposes
        decimals = 2;                            // Amount of decimals for display purposes
        symbol = "HYP";                               // Set the symbol for display purposes
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        address spender = _spender;
        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData);
        Approval(msg.sender, _spender, _value);
        return true;
    }
}
