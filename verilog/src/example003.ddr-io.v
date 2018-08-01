// from https://www.reddit.com/r/yosys/comments/7iue1l/estimating_critical_path_with_icetime/

// ddr_io.v
// Read DDR Input to a register and write to DDR output

module top (clk, ddr_in, ddr_out);
    input   wire        clk;
    input   wire        ddr_in; 
    output  wire        ddr_out;

    reg [1:0] in_buffer;
    reg [1:0] out_buffer;

    initial
    begin
        in_buffer = 0;
        out_buffer = 0;
    end

    // Differential input, DDR data
    defparam differential_input.PIN_TYPE = 6'b000000 ; // {NO_OUTPUT, PIN_INPUT_DDR}
    defparam differential_input.IO_STANDARD = "SB_LVDS_INPUT" ;
    SB_IO differential_input (
        .PACKAGE_PIN(ddr_in),
        .LATCH_INPUT_VALUE ( ),
        .CLOCK_ENABLE (1'b1),
        .INPUT_CLK (clk),
        .OUTPUT_CLK ( ),
        .OUTPUT_ENABLE ( ),
        .D_OUT_0 ( ),
        .D_OUT_1 ( ),
        .D_IN_0 (in_buffer[0]),
        .D_IN_1 (in_buffer[1])
    );

    // Differential output, DDR data
    defparam differential_output.PIN_TYPE = 6'b010000 ; // {PIN_OUTPUT_DDR}
    defparam differential_output.IO_STANDARD = "SB_LVCMOS" ;

    SB_IO differential_output (
        .PACKAGE_PIN(ddr_out),
        .LATCH_INPUT_VALUE ( ),
        .CLOCK_ENABLE (1'b1),
        .INPUT_CLK (clk),
        .OUTPUT_CLK ( ),
        .OUTPUT_ENABLE ( ),
        .D_OUT_0 (out_buffer[0]),
        .D_OUT_1 (out_buffer[1]),
        .D_IN_0 ( ),
        .D_IN_1 ( )
    );

    always @(posedge clk) begin
        out_buffer <= in_buffer;
    end

endmodule

module icestick (input CLK, DCDn, output DSRn);
	//top my_top_instance (.clk(CLK), .ddr_in(DCDn), .ddr_out(DSRn));
	//top my_top_instance (.clk(CLK), .ddr_in(DSRn), .ddr_out(DCDn));
	top my_top_instance (.clk(CLK));
endmodule

