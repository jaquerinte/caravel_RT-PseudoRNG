`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * prng_proj
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module prng_proj #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oen,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire valid;
    wire [2:0] prng_output;

    // WB MI A
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wbs_dat_o = {32{1'b0}};

    // IO
    assign io_out = {(`MPRJ_IO_PADS-4){prng_output}};
    assign io_oeb = {(`MPRJ_IO_PADS-1){rst}};

    // LA
    assign la_data_out = {128{1'b0}};
    
    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;

    
    reg [167:0] lfsr;
    wire [2:0] xnor_o;
    wire [3:0] check_0;
    wire [3:0] check_1;
    wire [3:0] check_2;

    initial begin
	    lfsr = 168'b111000110000011101000110000110100001010011100101111011001100111010000000100001100000110101000000011010010110001111001101000011000101110000010001100000000000101110000011;
    end

    always @(posedge clk) begin
        if (rst) begin
            xnor_o <= {3{1'b0}};
            check_0 <= {4{1'b0}};
            check_1 <= {4{1'b0}};
            check_2 <= {4{1'b0}};
        end else if (valid) begin
            xnor_o[2] <= ~(^{lfsr[167],lfsr[135],lfsr[103],lfsr[71]});
            xnor_o[1] <= ~(^{lfsr[166],lfsr[134],lfsr[102],lfsr[70]});
            xnor_o[0] <= ~(^{lfsr[165],lfsr[133],lfsr[101],lfsr[69]});
            check_2 <= {lfsr[167],lfsr[135],lfsr[103],lfsr[71]};
            check_1 <= {lfsr[166],lfsr[134],lfsr[102],lfsr[70]};
            check_0 <= {lfsr[165],lfsr[133],lfsr[101],lfsr[69]};
            prng_output <= xnor_o;
        end
    end

    always @(posedge clk) begin
	    if (rst == 1) begin
	        lfsr[WIDTH-1:0] <= 0;
        end else begin
	        lfsr[WIDTH-1:0] <= {lfsr[164:0],xnor_o};
        end
    end

endmodule


`default_nettype wire
