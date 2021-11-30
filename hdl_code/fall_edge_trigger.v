
module rise_edge_trigger(
	input clk,
	input reset,
	input level,
	output rise_edge
);

reg level_ff;

always@(posedge clk or posedge reset) begin
	if(reset) level_ff <= 1'b0;
	else level_ff <= level;
end

assign rise_edge = level & (~level_ff);


endmodule
