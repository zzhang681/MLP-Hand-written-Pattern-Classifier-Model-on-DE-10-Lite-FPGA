
/*
in[1]		w11	h[0]	w21	out[0]
			w12			w22
			w13			w23
in[2]		w14	h[1]	w24	out[1]

//w1 1 2 3 4	w2 5 6 7 8
//in: 1 2
//out: 5b 7b
*/

module simple_mlp #(
        // Size of Reads and Writes to the External Bridge to Avalon Bus
        // System
        parameter INTERFACE_WIDTH_BITS  = 128,
        // Number of entries in the Buffer
        parameter NUM_BUFFER_ENTRIES    = 64,
        // Number of bits used for the interface address space
        parameter INTERFACE_ADDR_BITS   = 26 
    )(
	input 									clk,
	input 									reset,
	input [INTERFACE_WIDTH_BITS-1:0] data,
	input										ack,
	input	[15:0]							in,
	output [15:0]					out

);

logic [31:0] w1, w2;
logic	[7:0]	h1, h2, o1, o2;
logic [2:0] cs, ns;

parameter IDLE = 3'b000;
parameter OUT = 3'b001;
/*
enum [2:0] {
	IDLE,
	HIDDEN,
	OUT
} cs, ns;
*/
assign w1 = data[31:0];
assign w2 = data[63:32];
assign out = {o2, o1};

always @(posedge clk) begin
	if(!reset) cs <= IDLE;
	else cs <= ns;
end

always_comb begin
	ns = cs;
	case(cs)
		IDLE: begin
			if(ack) ns = OUT;
			else ns = IDLE;
		end
		OUT: ns = IDLE;
	endcase
end

always @(*) begin
	h1 = 0;
	h2 = 0;
	case(cs)
		OUT: begin
			h1 = in[7:0] * w1[7:0] + in[15:8] * w1[15:8];
			h2 = in[7:0] * w1[23:16] + in[15:8] * w1[31:24];
			o1 = h1 * w2[7:0] + h2 * w2[15:8];
			o2 = h1 * w2[23:16] + h2 * w2[31:24];
		end
	endcase
end


endmodule