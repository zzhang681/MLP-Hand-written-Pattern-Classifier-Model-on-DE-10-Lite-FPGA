
module clock_divider
(clk,reset, clk_out);
 
input clk;
input reset;
output clk_out;

parameter WIDTH = 32; // Width of the register required
parameter N = 12500000;// We will divide by 12 for example in this case
//10s: 250_000_000
//1s: 25_000_000
//0.5s: 12_500_000


reg [WIDTH-1:0] r_reg;
wire [WIDTH-1:0] r_nxt;
reg clk_track;
 
always @(posedge clk or negedge reset)
 
begin
  if (!reset)
     begin
        r_reg <= 0;
	clk_track <= 1'b0;
     end
 
  else if (r_nxt == N)
 	   begin
	     r_reg <= 0;
	     clk_track <= ~clk_track;
	   end
 
  else 
      r_reg <= r_nxt;
end
 
 assign r_nxt = r_reg+1;   	      
 assign clk_out = clk_track;
 
endmodule
