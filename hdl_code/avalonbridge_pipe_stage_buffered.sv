

`timescale  1 ns / 1 ps
      
module avalonbridge_pipe_stage_buffered
    #(
                    parameter c_TDATA_WIDTH=128
    )
    (

                   
                    input wire i_axis_aclk,
                    input wire i_axis_aresetn,

                    input wire i_s_axis_tvalid,
                    output wire o_s_axis_tready,
                    input wire [c_TDATA_WIDTH-1:0] i_s_axis_tdata,

                    
                    output wire o_m_axis_tvalid,
                    input wire i_m_axis_tready,
                    output wire [c_TDATA_WIDTH-1:0] o_m_axis_tdata
);     
    /////////////////////////////////////////////////////////////
    reg [c_TDATA_WIDTH-1:0] data_bank_a = 0;
    reg [c_TDATA_WIDTH-1:0] data_bank_b = 0;
    
    reg bank_a_valid = 1'b0;
    reg bank_b_valid = 1'b0;

    reg write_bank_a_nb = 1'b1; //one implies bank a, zero implies bank b
    reg read_bank_a_nb = 1'b1;

    ///////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////
    assign o_s_axis_tready = (write_bank_a_nb) ? (!bank_a_valid) : (!bank_b_valid);
    assign o_m_axis_tvalid = (read_bank_a_nb) ? (bank_a_valid) : (bank_b_valid);
    assign o_m_axis_tdata = (read_bank_a_nb) ? (data_bank_a) : (data_bank_b);

    // Handle write data
    always @(posedge i_axis_aclk)
    begin
        if(i_s_axis_tvalid & o_s_axis_tready)
        begin
            if(write_bank_a_nb)
                data_bank_a <= i_s_axis_tdata;
            else
                data_bank_b <= i_s_axis_tdata;

            write_bank_a_nb <= ~write_bank_a_nb;
        end
    end

    // Handle read data
    always @(posedge i_axis_aclk)
    begin
        if(o_m_axis_tvalid & i_m_axis_tready)
        begin
            read_bank_a_nb <= ~read_bank_a_nb;
        end
    end

    //Handle bank valids
    always @(posedge i_axis_aclk)
    begin
			/*
			if(!i_axis_aresetn) begin
				bank_a_valid <= 1'b0;
				//bank_b_valid <= 1'b0;
			end else
		*/
			begin
        if(i_s_axis_tvalid & o_s_axis_tready & write_bank_a_nb)
            bank_a_valid <= 1'b1;
        else if(o_m_axis_tvalid & i_m_axis_tready & read_bank_a_nb)
            bank_a_valid <= 1'b0;

        if(i_s_axis_tvalid & o_s_axis_tready & (!write_bank_a_nb))
            bank_b_valid <= 1'b1;
        else if(o_m_axis_tvalid & i_m_axis_tready & (!read_bank_a_nb))
            bank_b_valid <= 1'b0;
			end
    end
    


endmodule 