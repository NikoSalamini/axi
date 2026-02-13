// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Niko Salamini <nikosalamini@gmail.com>

`include "common_cells/registers.svh"
`include "axi/typedef.svh"

module axi_traffic_generator #(
  /// Maximum number of AXI read bursts outstanding at the same time
  parameter int unsigned MaxReadTxns   = 32'd0,
  /// Maximum number of AXI write bursts outstanding at the same time
  parameter int unsigned MaxWriteTxns  = 32'd0,
  /// Number of bursts beats to be generated
  parameter int unsigned NumBurstBeats = 32'd256,
  // AXI Bus Types
  parameter int unsigned AddrWidth     = 32'd0,
  parameter int unsigned DataWidth     = 32'd0,
  parameter int unsigned IdWidth       = 32'd0,
  parameter int unsigned UserWidth     = 32'd0,
  parameter type         axi_req_t     = logic,
  parameter type         axi_resp_t    = logic,
  parameter type         axi_aw_chan_t = logic,
  parameter type         axi_w_chan_t  = logic,
  parameter type         axi_b_chan_t  = logic,
  parameter type         axi_ar_chan_t = logic,
  parameter type         axi_r_chan_t  = logic
)(
  input  logic  clk_i,  // clock
  input  logic  rst_ni, // active low

  // Input control signals
  input ext_start,      
  input ext_stop,

  // Output / Master Port
  output axi_req_t  mst_req_o,
  input  axi_resp_t mst_resp_i
);

/* FSM state */
enum logic {IDLE, START, INIT_NEW_BURST} state_d, state_q;

/* Burst's beats counter */
localparam int unsigned CntBeatsWidth = (NumBurstBeats > 1) ? $clog2(MaxWriteTxns) : 32'd1;
typedef logic [CntBeatsWidth-1:0] cnt_beats_t;
cnt_beats_t cnt_beats_d, cnt_beats_q;

// Outstanding Bursts (TODO)
// localparam int unsigned CntIdxWidth = (MaxWriteTxns > 1) ? $clog2(MaxWriteTxns) : 32'd1;
// typedef logic [CntIdxWidth-1:0]         cnt_idx_t;
// cnt_idx_t cnt_burst_id_d, cnt_burst_id_q;

/* logic to catch the pulses */
logic start_req_d, start_req_q;
logic stop_req_d,  stop_req_q;
`FFARN(start_req_q, stop_req_d, '0, clk_i, rst_ni)

// next state logic
always_comb begin

  // catch the pulses
  start_req_d = start_req_q;
  stop_req_d  = stop_req_q;

  // capture pulses
  if (ext_start)
    start_req_d = 1'b1;

  if (ext_stop)
    stop_req_d = 1'b1;

  // sticky state assignment
  state_d = state_q;

  // default AXI signal values
  mst_req_o.awvalid = '0;
  mst_req_o.awaddr  = '0;
  mst_req_o.wvalid  = '0;
  mst_req_o.wdata   = '0;
  mst_req_o.w_last  = '0

  // burst parameters. TODO: fixed parameters for now
  mst_req_o.aw.burst  = axi_pkg::BURST_INCR
  mst_req_o.aw.len    = 8'hFF;              // awlen + 1 = num_beats_burst
  mst_req_o.aw.size   = $clog2(DataWidth/8); // bytes per beat = 2^size. Set to the max size according to DataWidth. 

  // burst counter assignment
  cnt_beats_d = cnt_beats_q;

  // switch case 
  case (state_q)

    // pulse received, init parameters, starting sending data
    IDLE: begin
      // wait for start pulse and aw_ready == 1
      if (start_req_q == '1 && mst_resp_i.aw_ready == 1) begin 
          start_req_d         = '1; // clear start request
          mst_req_o.awvalid   = '1; // set awvalid
          mst_req_o.awaddr    = '0; // TODO: configurable address range
          state_d             = INIT_BURST_DATA;
        end
      end
    end

    // init burst data
    INIT_BURST_DATA: begin
      // TODO: NO need to wait aw_ready = 0, merge this state with the other
      if (mst_resp_i.w_ready == 1) begin
          /* send first beat */
          mst_req_o.wvalid  = 1; 
          mst_req_o.wdata   = 1;              // TODO: assign random or incremental data
          cnt_beats_d       = 1;               // counter initialized to 1
          state_d           = SEND_UNTIL_LAST;  
      end
    end

    // send all the beats and set wlast
    SEND_UNTIL_LAST: begin
      if (mst_resp_i.w_ready == 1) begin

        // assignments
        mst_req_o.wdata = cnt_beats_q == '1? 0 : cnt_beats_q + 1;  // next value
        cnt_beats_d     = cnt_beats_q == '1? 0 : cnt_beats_q + 1;  // update counter

        // if this is the last beat, set wlast and change state
        if (cnt_beats_q == NumBurstBeats - 1) begin
          mst_req_o.w_last  = '1;
          if (ext_stop) begin
            state_d = STOP;
          end
          else begin
            state_d = INIT_BURST_DATA;
          end
        end

      end
      else begin
        /* keep the same value for data and counter */
      end
    end

    // wait for stop pulse
    STOP: begin
      if (!ext_stop)
        state_d = IDLE;
    end

    default: state_d = IDLE;

  endcase
end


// Regs
`FFARN(state_q, state_d, IDLE, clk_i, rst_ni)
`FFARN(cnt_beats_q, cnt_beats_d, '0, clk_i, rst_ni)
// `FFARN(cnt_burst_id_q, cnt_burst_id_d, IDLE, clk_i, rst_ni)

// always_comb begin
  




//   case (current_state)

//     IDLE: begin
//       /* nothing happens */
//     end

//     START: begin
//       /* wait for pulse */
//     end

//     DATA: begin
//       /* burst loop */

//       // REQ channel
      

//       // RSP channel
//       if (mst_resp_i.b_valid == '1) begin
//       end
//     end
//   endcase
// end



// // // output logic
// // always_comb begin
// //   // defaults
// //   mst_req_o = '0;      // VERY important default

// //   case (current_state)

// //     IDLE: begin
// //       // nothing happening
// //     end

// //     START: begin 
// //       // optional init of counters 
// //     end

// //     DATA: begin
// //       // traffic generation
// //     end

// //     STOP: begin
// //       // wait for all the transaction to end
// //     end

// //   endcase
// // end




