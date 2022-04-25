pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    int clock;
    State st;
    address timeAdd;
    
    constructor(address adr_input) public {
        st = State.Working;
        disc = 0;
        clock = 0;
        timeAdd = adr_input;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
    }

    function collect_1_Y() public {
        require( st == State.Completed );
        require( clock < 4 );
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed );
        require( clock == 4 );
        st = State.Delay;
        disc = 5;
    }

    function collect_2_Y() external {
        require( st == State.Delay );
        require( clock < 8 );
        require( clock >= 4 );
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay );
        require( clock == 8 );
        st = State.Forfeit;
        disc = 0;
    }
    
    function tick() public {
        require( msg.sender == timeAdd );
        clock=clock+1;
    }

}

contract Supplier {
    
    Paylock p;

    Rental r;
    
    enum State { Working , Completed }

    enum State_acquired {acquired , returned }
    
    State st;

    State_acquired sta;

    
    constructor(address pp, address rt) public {
        p = Paylock(pp);
        r = Rental(rt);
        st = State.Working;
        sta = State_acquired.returned;
    }
    
    function finish() external {
        require (st == State.Working);
        p.signal();
        st = State.Completed;
    }
    
    function aquire_resource() public {
        require (sta == State_acquired.returned);
        r.rent_out_resource(this);
        sta = State_acquired.acquired;
    }

    function return_resource() public {
        require(sta == State_acquired.acquired);
        r.retrieve_resource();
        sta = State_acquired.returned;
    }

    receive() external payable {
	    if (address(r).balance > 1 ether) {
		r.retrieve_resource();
	    }

    }
    
}

contract Rental {
    
    address resource_owner;
    bool resource_available;
    
    constructor() public {
        resource_available = true;
    }
    
    function rent_out_resource(Supplier supplier) payable external {
        require(resource_available == true);
        require(msg.value == 1 wei);
        resource_owner = address(supplier);
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false);
	resource_available = true;
        address(resource_owner).call.value(1 wei)("");
        
    }
    
}