`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Amaan Rehman Shah
// 
// Create Date: 05/10/2025 11:14:50 PM
// Design Name: 
// Module Name: asymfifo
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


module asymfifo #(
    
    parameter int DSIZE = 32,
    parameter int DEPTH = 8

)(

    // Write Side
    input  logic             i_wclk,
    input  logic             i_wrst,
    input  logic             i_wr,
    input  logic [DSIZE-1:0] i_wdata,
    output logic             o_wfull,
     
    // Read Side
    
    input  logic             i_rclk,
    input  logic             i_rrst,
    input  logic             i_rd,
    output logic [DSIZE-1:0] o_rdata,
    output logic             o_rempty
);

    localparam int AW = DEPTH;
    localparam int DW = DSIZE;
    typedef logic [DW-1:0] data_t;
    typedef logic [AW-1:0] addr_t;
    typedef logic [AW:0]   ptr_t;               // one bit extra for full/empty
    
    ptr_t wbin, wgray, wbinnext, wgraynext;
    ptr_t wq1_rgray, wq2_rgray;
    
    addr_t w_addr;
    
    logic wfull_next;
    
    always_ff @(posedge i_wclk or posedge i_wrst) begin
        
        if (i_wrst) begin
            {wq2_rgray, wq1_rgray} <= '0;  
        end else
            {wq2_rgray, wq1_rgray} <= {wq1_rgray, rgray};
    end
    
    // next-state write pointer
    always_comb begin
        wbinnext  = wbin + (i_wr && !o_wfull);
        wgraynext = (wbinnext >> 1) ^ wbinnext;
        wfull_next = (wgraynext == { ~wq2_rgray[AW:AW-1], wq2_rgray[AW-2:0] });
    end

    // register write pointer
    always_ff @(posedge i_wclk or posedge i_wrst) begin
        if (i_wrst)
            {wbin, wgray} <= '0;
        else
            {wbin, wgray} <= {wbinnext, wgraynext};
    end

    assign o_wfull  = wfull_next;

    //--------------------------------------------------------------------------
    // read-side pointer & sync
    //--------------------------------------------------------------------------
    ptr_t rbin, rgray, rbinnext, rgraynext;
    ptr_t rq1_wgray, rq2_wgray;
    addr_t raddr, waddr;
    logic  rempty_next;
    
    assign waddr    = wbin[AW-1:0];


    // sync write-pointer (gray) into read clock domain
    always_ff @(posedge i_rclk or posedge i_rrst) begin
        if (i_rrst)
            {rq2_wgray, rq1_wgray} <= '0;
        else
            {rq2_wgray, rq1_wgray} <= {rq1_wgray, wgray};
    end

    // next-state read pointer
    always_comb begin
        rbinnext   = rbin + (i_rd && !o_rempty);
        rgraynext  = (rbinnext >> 1) ^ rbinnext;
        rempty_next = (rgraynext == { ~rq2_wgray[AW:AW-1], rq2_wgray[AW-2:0] });
    end

    // register read pointer
    always_ff @(posedge i_rclk or posedge i_rrst) begin
        if (i_rrst)
            {rbin, rgray} <= '0;
        else
            {rbin, rgray} <= {rbinnext, rgraynext};
    end

    assign raddr    = rbin[AW-1:0];
    assign o_rempty = rempty_next;

    //--------------------------------------------------------------------------
    // dual-port Block RAM
    //   - port A = write (i_wclk)
    //   - port B = read  (i_rclk), synchronous output
    //--------------------------------------------------------------------------
//    (* ram_style = "block" *) 
    logic [DW-1:0] mem [0:(1<<AW)-1];

    // write port
    always_ff @(posedge i_wclk) begin
        if (i_wr && !o_wfull)
            mem[waddr] <= i_wdata;
    end

    // read port (registered output)
    always_ff @(posedge i_rclk or posedge i_rrst) begin
        if (i_rrst)
            o_rdata <= '0;
        else if (i_rd && !o_rempty)
            o_rdata <= mem[raddr];
    end
    
endmodule
