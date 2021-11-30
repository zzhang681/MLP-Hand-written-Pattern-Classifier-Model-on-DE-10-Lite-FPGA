
//module for reading data

module sdram_reader #(
        // Size of Reads and Writes to the External Bridge to Avalon Bus
        // System
        parameter INTERFACE_WIDTH_BITS  = 128,
        // Number of entries in the Buffer
        parameter NUM_BUFFER_ENTRIES    = 64,
        // Number of bits used for the interface address space
        parameter INTERFACE_ADDR_BITS   = 26 
    )(
        // CLOCKS //

        // Clock for the interface to the QSYS system
        input interface_clock,
        // Clock used by the VGA circuitry.
        //input read_clock,
        // System reset
        input reset_n,

        // QSYS INTERFACE //
        output logic [INTERFACE_ADDR_BITS-1:0]        interface_address,
        output logic [(INTERFACE_WIDTH_BITS / 8)-1:0] interface_byte_enable,
        output logic                            interface_read,
        output                                  interface_write,
        input [INTERFACE_WIDTH_BITS-1:0]        interface_read_data,
        //output [INTERFACE_WIDTH_BITS-1:0]       interface_write_data,
        input                                   interface_acknowledge,
		  input  next_img,
		  input  read_img_start,
		  input  mac_start,
		  input  mac_done,
		  input  full_fifo,
		  input  empty_fifo,
		  output	logic[INTERFACE_WIDTH_BITS-1:0]			data_reg,
		  output read_done,
		  output read_done_w2,
		  output logic acknowledge_flag,
		  output [4:0] states,
		  output logic [9:0] addr_r,
		  output [7:0] dr_ram,
		  output o_write_req_fifo,
		  output reg ack
			/*
        // General Module IO
        input [$clog2(NUM_BUFFER_ENTRIES)-1:0] read_address,
        output [INTERFACE_WIDTH_BITS-1:0]      read_data,

        // When asserted, begin buffering the next row.
        input start,
        // Byte address to begin buffering from.
        input [INTERFACE_ADDR_BITS-1:0] base_address,
			
        // Error indication
        output logic    timing_error,
        input           timing_error_reset
		  */
);

logic clk, reset;
logic edge_det_IDLE, edge_IDLE, buffer_read, write_ram, read_ram;
logic [3:0] counter;
logic [9:0] addr_w;
logic [7:0] data_w_8;

logic fifo_full_test;
assign fifo_full_test = (!full_fifo) & cs == READ;

assign clk = interface_clock;
assign reset = reset_n;

logic [INTERFACE_ADDR_BITS-1:0] interface_address_next;

localparam INTERFACE_WIDTH_BYTES = INTERFACE_WIDTH_BITS / 8;

//assign interface_byte_enable = (2 ** INTERFACE_WIDTH_BYTES) - 1;

parameter ADDR_W1 = 0;
parameter ADDR_W1_FIN = 200703;
parameter ADDR_BIAS1 = 200704;
parameter ADDR_BIAS1_FIN = 200959;
parameter ADDR_W2 = 200960;
parameter ADDR_W2_FIN = 203519;
parameter ADDR_BIAS2 = 203520;
parameter ADDR_BIAS2_FIN = 203559;

parameter final_address = ADDR_BIAS2_FIN + 1;//544;		//200688, 200704， 203264		//op# = address / 16
parameter final_w1 = 200704;
parameter IMG_BYTES = 784;

parameter img_address = 204000;			//204000-204783-205079 (addr 205088)
parameter img_address_fin = img_address + IMG_BYTES - 1;// + 296 - 40;
parameter c_TDATA_WIDTH=128;


logic [127:0] data_weight, data_img;
assign data_reg = data_weight;

logic [7:0] retry;		//20
parameter RETRY = 100;

always_ff @(posedge clk) begin
	if(!reset) retry <= 0;
	else begin
		if(O_intf_read_img && cs == READ_IMG) begin
			if(retry < RETRY) retry <= retry + 1;
			else retry <= 0;
		end else retry <= 0;
	end
end

always_ff @(posedge clk) begin
	if(!reset) interface_address <= 0;
	else interface_address <= interface_address_next;
end


enum bit[3:0] {
	IDLE,
	READ_IMG_START,
	READ_IMG_START2,
	READ_IMG,
	READ_IMG_DONE,
	READ_IMG_FIN,
	READ_START,
	READ,
	READ_DONE,
	OP,
	OP_DONE,
	ALL_DONE,
	READ_IMG_STORE
} cs, ns;

/*
parameter IDLE = 5'b00000;
parameter READ_IMG_START = 5'b00001;
parameter READ_IMG_START2 = 5'b00010;
parameter READ_IMG = 5'b00011;
parameter READ_IMG_DONE = 5'b00100;
parameter READ_IMG_FIN = 5'b00101;
parameter READ_START = 5'b00110;
parameter READ = 5'b00111;
parameter READ_DONE = 5'b01000;
parameter OP = 5'b01001;
parameter OP_DONE = 5'b01010;
parameter ALL_DONE = 5'b01011;
read_img_store = 5'b01100

logic [4:0] cs, ns;
*/
assign states = cs;
assign read_done = (cs == ALL_DONE)?1:0;//(cs == READ && interface_address >= final_w1) ? 1 : 0;
assign read_done_w2 = (cs == ALL_DONE)?1:0;
assign edge_det_IDLE = (cs == IDLE) ? 1:0;

always begin
	//interface_address=0;
   interface_byte_enable=16'hffff;
   //interface_read=1'b1;
   interface_write = 1'b0;
end


//logic ack;
assign ack = (cs == READ_IMG_FIN) ? 1 : 0;//(cs == ALL_DONE) ? 1:0;

always_latch begin
	case(cs)
		IDLE: acknowledge_flag <= 0;
		//READ_IMG_START2: acknowledge_flag = 0;
		READ_IMG_DONE: acknowledge_flag <= 0;
		READ_IMG_FIN: acknowledge_flag <= 0;
		READ_START: acknowledge_flag <= 0;
		READ_DONE: acknowledge_flag <= 0;
		default: begin
			if(interface_acknowledge) acknowledge_flag <= 1;
		end
	endcase
end

always_comb begin
	ns = cs;
	case(cs)
		IDLE: begin
			if(mac_start) ns = READ_START;
			else if(read_img_start) ns = READ_IMG_START;
			else ns = IDLE;
		end
		
		READ_IMG_START: begin
			if(interface_acknowledge) ns = READ_IMG;
			else ns = READ_IMG_START;
		end
		
		READ_IMG: begin
			//if(retry < RETRY) begin
				if(addr_w >= IMG_BYTES - 1) ns = READ_IMG_FIN;
				else ns = READ_IMG;
			//end else ns = READ_IMG_START;
		end
		
		READ_IMG_FIN: begin 
			ns = READ_START;
		end
		
		
		READ_START: ns = READ;
		
		READ: begin
			if(interface_address >= final_address) ns = ALL_DONE;
			else ns = READ;
		end
		
		ALL_DONE: ns = ALL_DONE;
		
	endcase
end

//interface_address
always @(*) begin
	interface_address_next = interface_address;
	begin
		case(cs)
			IDLE: interface_address_next = img_address;
			
			READ_IMG_START: begin
				if(interface_acknowledge) begin 
					if(interface_address < img_address_fin) interface_address_next = interface_address + 16;
					//else interface_address_next = interface_address;
				end else interface_address_next = interface_address;
			end
			
			READ_IMG_START2: interface_address_next = interface_address;
			
			READ_IMG: begin
				if(interface_acknowledge) begin 
					if(interface_address < img_address_fin) interface_address_next = interface_address + 16;
					//else interface_address_next = interface_address;
				end else interface_address_next = interface_address;
			end
			
			//READ_IMG_DONE: interface_address_next = interface_address + 5'h10;
			
			READ_IMG_FIN: interface_address_next = 0;//interface_address;
			
			READ_START: interface_address_next = 0;
			
			READ: begin
				if(interface_acknowledge) begin 
					if(interface_address < final_address) interface_address_next = interface_address + 16;
					//else interface_address_next = interface_address;
				end else interface_address_next = interface_address;
			end
			
			default: interface_address_next = interface_address;
		endcase
	end
end

//counter
always @(posedge interface_clock) begin
	if(!reset) counter <= 0;
	else begin
		if(cs == READ_IMG) begin
			case(counter)
				0: begin
					if(write_ram) counter <= counter + 1;
					else counter <= 0;
				end
				
				15: counter <= 0;
				default: counter <= counter + 1;
			endcase
		end else counter <= 0;
	end
end

always @(*) begin
	buffer_read = 0;
	case(cs)
		IDLE: buffer_read = 0;
		READ_IMG_START: buffer_read = 1;
		READ_IMG: begin
			if(counter >= 0 && counter < 15 && write_ram) buffer_read = 0;
			else buffer_read = 1;
		end
		READ_IMG_FIN: buffer_read = 0;
	endcase
end

//addr_w
always_ff @(posedge interface_clock) begin
	if(!reset) addr_w <= 0;
	else begin
		if(cs == READ_IMG) begin
			if(write_ram) addr_w <= addr_w + 1;
		end else if (cs == READ_IMG_START) addr_w <= 0;
		else if(cs == ALL_DONE || cs == READ) addr_w <= addr_r;
		else addr_w <= 0;
	end
end

logic[127:0] data_img_reg;

always @(posedge interface_clock) begin
	if(!reset) data_img_reg <= 0;
	else begin
		if(write_ram && counter == 0) data_img_reg <= data_img >> 8;
		else if(write_ram && counter < 15) data_img_reg <= data_img_reg >> 8;
		else data_img_reg <= 0;
	end
end


always @(*) begin
	if(counter == 0) data_w_8 = data_img[7:0];
	else data_w_8 = data_img_reg[7:0];
end

always_ff @(posedge interface_clock) begin
	if(!reset) addr_r <= 0;
	else begin
		if(next_img) addr_r <= addr_r + 1;		//read_img_start, next_img, cs == ALL_DONE
	end
end

always @(*) begin
	read_ram = 1;
end


//interface_read
/*
always@(*) begin
	interface_read = 1'b0;
	begin 
		case(cs)
			IDLE: begin
				interface_read = 1'b1;
			end
			
			READ_IMG_START: interface_read = 1'b1;
			
			READ_IMG_START2: interface_read = 1'b1;
			
			READ_IMG: begin
				interface_read = 1'b1;
				//if(interface_acknowledge) interface_read = 1'b0;
				//else interface_read = 1'b1;
			end
			
			READ_START: interface_read = 1'b1;
			
			READ: begin
				interface_read = 1'b1;
			end
			
			//OP_DONE: interface_read = 1'b1;
			//ALL_DONE: interface_read = 1'b1;
			
			default: interface_read = 1'b0;
		endcase
	end
end
*/



//data_reg
/*
always_ff @(posedge clk) begin
	if(!reset) data_reg <= 0;
	else begin
		if(interface_acknowledge) data_reg <= interface_read_data;
		else data_reg <= data_reg;
	end
end
*/
//assign data_reg = interface_address;
//assign data_reg = count;

/*
logic [127:0] data_cap;

always_latch begin
	if(!reset) data_cap = 0;
	else if(interface_acknowledge) data_cap = interface_read_data;
end
*/
/*
always_ff @(posedge clk) begin
	if(!reset) data_reg <= 0;
	else 
	begin
		if(interface_acknowledge) data_reg <= interface_read_data;
		else data_reg <= data_reg;
	end
end
*/

//cs
always_ff @(posedge clk) begin
	if(!reset) cs <= IDLE;
	else cs <= ns;
end

logic O_intf_read_img, o_intf_read_weight,i_s_axis_tvalid, o_m_axis_tvalid;

assign i_s_axis_tvalid = (cs == READ_IMG || cs == READ_IMG_START) ? interface_acknowledge : 0;

assign write_ram = (cs == READ_IMG) ? o_m_axis_tvalid : 0;

//interface_read
always @(*) begin
	interface_read = 0;
	case(cs)
		READ_IMG_START: interface_read = O_intf_read_img;
		READ_IMG: interface_read = O_intf_read_img;
		READ: if(!full_fifo) interface_read = 1;
	endcase
end

//o_write_req_fifo
always @(*) begin
	o_write_req_fifo = 0;
	case(cs)
		READ: begin
			if(!full_fifo) o_write_req_fifo = interface_acknowledge;
		end
	endcase
end


rise_edge_trigger rr1(
	.clk(clk),
	.reset(reset),
	.level(edge_det_IDLE),
	.rise_edge(edge_IDLE)
);

avalonbridge_pipe_stage_buffered #(
	.c_TDATA_WIDTH(c_TDATA_WIDTH)
) u1 (
	.i_axis_aclk(interface_clock),
	.i_axis_aresetn(reset_n),
	
	.i_s_axis_tvalid(i_s_axis_tvalid),
	.o_s_axis_tready(O_intf_read_img),
	.i_s_axis_tdata(interface_read_data),
	
	.o_m_axis_tvalid(o_m_axis_tvalid),
	.i_m_axis_tready(buffer_read),
	.o_m_axis_tdata(data_img)
); 


img_ram8 u3(
	.address(addr_w),
	.clock(interface_clock),
	.data(data_w_8),
	.wren(write_ram),
	.q(dr_ram)
);


endmodule