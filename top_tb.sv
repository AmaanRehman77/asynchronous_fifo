`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Amaan Rehman Shah
// 
// Create Date: 05/11/2025 01:46:27 PM
// Design Name: 
// Module Name: top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps
`default_nettype none

module top_tb;

  // parameters must match the DUT
  localparam int DSIZE = 8;
  localparam int ASIZE = 4;
  localparam int DEPTH  = 1 << ASIZE;

  // clocks & resets
  logic wclk = 0;
  logic rclk = 0;
  logic wrst, rrst;

  // DUT interface
  logic              i_wr;
  logic [DSIZE-1:0]  i_wdata;
  logic              o_wfull;

  logic              i_rd;
  logic [DSIZE-1:0]  o_rdata;
  logic              o_rempty;

  // write/read pointers for checking
  integer write_count = 0;
  integer read_count  = 0;

  // instantiate the FIFO
  asymfifo #(
    .DSIZE(DSIZE),
    .DEPTH(ASIZE)
  ) dut (
    .i_wclk   (wclk),
    .i_wrst   (wrst),
    .i_wr     (i_wr),
    .i_wdata  (i_wdata),
    .o_wfull  (o_wfull),

    .i_rclk   (rclk),
    .i_rrst   (rrst),
    .i_rd     (i_rd),
    .o_rdata  (o_rdata),
    .o_rempty (o_rempty)
  );

  // generate clocks
  always #5   wclk = ~wclk;   // 100 MHz
  always #6.25 rclk = ~rclk;  // 80 MHz

  // reset both domains
  initial begin
    wrst = 1;
    rrst = 1;
    #20;
    wrst = 0;
    rrst = 0;
  end

  // write stimulus
  initial begin
    i_wr    = 0;
    i_wdata = '0;
    i_rd    = 0;
    @(negedge wrst);
    @(posedge wclk);

    // write DEPTH+2 words to test full behavior
    repeat (DEPTH + 2) begin
      @(posedge wclk);
      if (!o_wfull) begin
        i_wr    <= 1;
        i_wdata <= write_count[DSIZE-1:0];
        $display("[%0t] WRITE: %0d", $time, write_count);
        write_count++;
      end
      else begin
        i_wr <= 0;
        $display("[%0t] WRITE PAUSED (full)", $time);
      end
    end

    // stop writes
    @(posedge wclk);
    i_wr = 0;
  end

 // read stimulus
 initial begin
   i_rd = 0;
   @(negedge rrst);
   @(posedge rclk);

   // wait for some data to accumulate
   #100;

   // read until we've read what was written
   while (read_count < write_count) begin
     @(posedge rclk);
     if (!o_rempty) begin
       i_rd <= 1;
       @(posedge rclk);
       i_rd <= 0;
       $display("[%0t] READ : %0d", $time, o_rdata);
//        @(posedge rclk);
       if (o_rdata !== (read_count[DSIZE-1:0] - 1)) begin
         $error("DATA MISMATCH at count %0d: got %0d", read_count, o_rdata);
       end
//        @(posedge rclk);
       read_count++;
     end
     else begin
       i_rd <= 0;
       $display("[%0t] READ PAUSED (empty)", $time);
     end
   end

   $display("** Test complete: wrote %0d words, read %0d words **", write_count, read_count);
   #20;
   $finish;
 end

  // optional: waveform dump
//  initial begin
//    $dumpfile("tb_afifo.vcd");
//    $dumpvars(0, tb_afifo);
//  end

endmodule
