`timescale 1ns / 1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_1_pkg::*;

// clk and rst
bit clk         = 0;
bit resetn      = 0;
bit ext_start   = 0;
bit ext_stop    = 0;

module tb_AXI_VIP_Master();
always #5ns clk = ~clk;

design_1_wrapper DUT
(
    .clk_0(clk),
    .resetn_0(resetn),
    .ext_start_0(ext_start),
    .ext_stop_0(ext_stop)
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

    // -------------------------
    // START PULSE
    // -------------------------
    @(posedge clk);
    ext_start = 1;
    @(posedge clk);
    ext_start = 0;

    // wait some time (traffic running)
    #10000ns

    // -------------------------
    // STOP PULSE
    // -------------------------
    @(posedge clk);
    ext_stop = 1;
    @(posedge clk);
    ext_stop = 0;
end
endmodule


