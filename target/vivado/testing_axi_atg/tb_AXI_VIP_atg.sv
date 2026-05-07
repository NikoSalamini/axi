`timescale 1ns / 1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_1_pkg::*;

// address width
localparam int unsigned AddrWidth = 32'd48;
localparam int unsigned SkipCyclesWidth = 32'd8;

// clk and rst
bit clk         = 0;
bit resetn      = 0;
bit ext_start   = 0;
bit ext_stop    = 0;
bit [AddrWidth-1:0] start_address_i = 32'h8ffe0000;
bit [SkipCyclesWidth-1:0] skip_cycles_i = 32'h00000008;

module tb_AXI_VIP_Master();
always #5ns clk = ~clk;

design_1_wrapper DUT
(
    .clk_0(clk),
    .resetn_0(resetn),
    .ext_start_0(ext_start),
    .ext_stop_0(ext_stop),
    .start_address_i_0(start_address_i),
    .skip_cycles_i_0(skip_cycles_i)
);

design_1_axi_vip_0_1_slv_mem_t slv_agent;

initial begin
    // slave agent
    slv_agent = new("slave vip agent",DUT.design_1_i.axi_vip_0.inst.IF);

    // set tag for agents for easy debug
    slv_agent.set_agent_tag("Slave VIP");

    // Start the agent
    slv_agent.start_slave();

    // reset
    resetn = 0; 
    #250ns  
    resetn = 1;
    #50ns

    // setting the address and skip cycles
    start_address_i = 48'h0; 
    skip_cycles_i = 32'h00000000;

    // -------------------------
    // START PULSE
    // -------------------------
    @(posedge clk);
    ext_start = 1;
    @(posedge clk);
    ext_start = 0;

    // wait some time (traffic running)
    #50000ns

    // -------------------------
    // STOP PULSE
    // -------------------------
    @(posedge clk);
    ext_stop = 1;
    @(posedge clk);
    ext_stop = 0;

    skip_cycles_i = 32'h00000001;

    // -------------------------
    // START PULSE
    // -------------------------

    @(posedge clk);
    ext_start = 1;
    @(posedge clk);
    ext_start = 0;

    // wait some time (traffic running)
    #50000ns

    // -------------------------
    // STOP PULSE
    // -------------------------
    @(posedge clk);
    ext_stop = 1;
    @(posedge clk);
    ext_stop = 0;

    // // -------------------------
    // // START PULSE
    // // -------------------------
    // @(posedge clk);
    // ext_start = 1;
    // // start_address_i = 48'h8; // setting the addresses
    // @(posedge clk);
    // ext_start = 0;

    // // wait some time (traffic running)
    // #5000ns

    // -------------------------
    // STOP PULSE
    // -------------------------
    @(posedge clk);
    ext_stop = 1;
    @(posedge clk);
    ext_stop = 0;

end
endmodule


