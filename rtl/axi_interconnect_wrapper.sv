// -----------------------------------------------------------------------------
// File Name   : axi_interconnect_wrapper.sv
// Description : Packaging wrapper for axi_interconnect.
//               Option A revision:
//                 - WSTRB / WLAST / RLAST exposed as real ports on all 5 buses
//                 - AWLEN/AWSIZE/AWBURST and ARLEN/ARSIZE/ARBURST driven as
//                   constants on the master side (single beat, 4 bytes, INCR)
//               NOTE: burst requests from the master side are NOT honored.
//                     Single-beat accesses only (Xil_Out32 / Xil_In32).
// -----------------------------------------------------------------------------

module axi_interconnect_wrapper (
    input wire aclk,
    input wire aresetn,

    // =========================================================
    // SLAVE INTERFACES (Connect to external Masters - e.g. Zynq)
    // =========================================================

    // --- S00_AXI (Master 0) ---
    input  wire [31:0] s00_axi_awaddr, input wire [3:0] s00_axi_awid, input wire [7:0] s00_axi_awlen, input wire [2:0] s00_axi_awsize, input wire [1:0] s00_axi_awburst, input wire s00_axi_awvalid, output wire s00_axi_awready,
    input  wire [31:0] s00_axi_wdata,  input wire [3:0] s00_axi_wstrb, input wire s00_axi_wlast, input wire s00_axi_wvalid, output wire s00_axi_wready,
    output wire [1:0]  s00_axi_bresp,  output wire [3:0] s00_axi_bid, output wire s00_axi_bvalid, input wire s00_axi_bready,
    input  wire [31:0] s00_axi_araddr, input wire [3:0] s00_axi_arid, input wire [7:0] s00_axi_arlen, input wire [2:0] s00_axi_arsize, input wire [1:0] s00_axi_arburst, input wire s00_axi_arvalid, output wire s00_axi_arready,
    output wire [31:0] s00_axi_rdata,  output wire [1:0] s00_axi_rresp, output wire [3:0] s00_axi_rid, output wire s00_axi_rlast, output wire s00_axi_rvalid, input wire s00_axi_rready,
    
    // --- S01_AXI (Master 1) ---
    input  wire [31:0] s01_axi_awaddr, input wire [3:0] s01_axi_awid, input wire [7:0] s01_axi_awlen, input wire [2:0] s01_axi_awsize, input wire [1:0] s01_axi_awburst, input wire s01_axi_awvalid, output wire s01_axi_awready,
    input  wire [31:0] s01_axi_wdata,  input wire [3:0] s01_axi_wstrb, input wire s01_axi_wlast, input wire s01_axi_wvalid, output wire s01_axi_wready,
    output wire [1:0]  s01_axi_bresp,  output wire [3:0] s01_axi_bid, output wire s01_axi_bvalid, input wire s01_axi_bready,
    input  wire [31:0] s01_axi_araddr, input wire [3:0] s01_axi_arid, input wire [7:0] s01_axi_arlen, input wire [2:0] s01_axi_arsize, input wire [1:0] s01_axi_arburst, input wire s01_axi_arvalid, output wire s01_axi_arready,
    output wire [31:0] s01_axi_rdata,  output wire [1:0] s01_axi_rresp, output wire [3:0] s01_axi_rid, output wire s01_axi_rlast, output wire s01_axi_rvalid, input wire s01_axi_rready,
    
    // =========================================================
    // MASTER INTERFACES (Connect to external Slaves - e.g. BRAM)
    // =========================================================

    // --- M00_AXI (Slave 0) ---
    output wire [31:0] m00_axi_awaddr, output wire [3:0] m00_axi_awid, output wire [7:0] m00_axi_awlen, output wire [2:0] m00_axi_awsize, output wire [1:0] m00_axi_awburst, output wire m00_axi_awvalid, input wire m00_axi_awready,
    output wire [31:0] m00_axi_wdata,  output wire [3:0] m00_axi_wstrb, output wire m00_axi_wlast, output wire m00_axi_wvalid, input wire m00_axi_wready,
    input  wire [1:0]  m00_axi_bresp,  input wire [3:0] m00_axi_bid, input wire m00_axi_bvalid, output wire m00_axi_bready,
    output wire [31:0] m00_axi_araddr, output wire [3:0] m00_axi_arid, output wire [7:0] m00_axi_arlen, output wire [2:0] m00_axi_arsize, output wire [1:0] m00_axi_arburst, output wire m00_axi_arvalid, input wire m00_axi_arready,
    input  wire [31:0] m00_axi_rdata,  input wire [1:0] m00_axi_rresp, input wire [3:0] m00_axi_rid, input wire m00_axi_rlast, input wire m00_axi_rvalid, output wire m00_axi_rready,

    // --- M01_AXI (Slave 1) ---
    output wire [31:0] m01_axi_awaddr, output wire [3:0] m01_axi_awid, output wire [7:0] m01_axi_awlen, output wire [2:0] m01_axi_awsize, output wire [1:0] m01_axi_awburst, output wire m01_axi_awvalid, input wire m01_axi_awready,
    output wire [31:0] m01_axi_wdata,  output wire [3:0] m01_axi_wstrb, output wire m01_axi_wlast, output wire m01_axi_wvalid, input wire m01_axi_wready,
    input  wire [1:0]  m01_axi_bresp,  input wire [3:0] m01_axi_bid, input wire m01_axi_bvalid, output wire m01_axi_bready,
    output wire [31:0] m01_axi_araddr, output wire [3:0] m01_axi_arid, output wire [7:0] m01_axi_arlen, output wire [2:0] m01_axi_arsize, output wire [1:0] m01_axi_arburst, output wire m01_axi_arvalid, input wire m01_axi_arready,
    input  wire [31:0] m01_axi_rdata,  input wire [1:0] m01_axi_rresp, input wire [3:0] m01_axi_rid, input wire m01_axi_rlast, input wire m01_axi_rvalid, output wire m01_axi_rready,

    // --- M02_AXI (Slave 2) ---
    output wire [31:0] m02_axi_awaddr, output wire [3:0] m02_axi_awid, output wire [7:0] m02_axi_awlen, output wire [2:0] m02_axi_awsize, output wire [1:0] m02_axi_awburst, output wire m02_axi_awvalid, input wire m02_axi_awready,
    output wire [31:0] m02_axi_wdata,  output wire [3:0] m02_axi_wstrb, output wire m02_axi_wlast, output wire m02_axi_wvalid, input wire m02_axi_wready,
    input  wire [1:0]  m02_axi_bresp,  input wire [3:0] m02_axi_bid, input wire m02_axi_bvalid, output wire m02_axi_bready,
    output wire [31:0] m02_axi_araddr, output wire [3:0] m02_axi_arid, output wire [7:0] m02_axi_arlen, output wire [2:0] m02_axi_arsize, output wire [1:0] m02_axi_arburst, output wire m02_axi_arvalid, input wire m02_axi_arready,
    input  wire [31:0] m02_axi_rdata,  input wire [1:0] m02_axi_rresp, input wire [3:0] m02_axi_rid, input wire m02_axi_rlast, input wire m02_axi_rvalid, output wire m02_axi_rready
);

    // 1. Instantiate the SystemVerilog Interfaces
    axi_if m0_if();
    axi_if m1_if();
    axi_if s0_if();
    axi_if s1_if();
    axi_if s2_if();

    // 2. Connect the physical clocks to the interfaces
    assign m0_if.aclk = aclk; assign m0_if.aresetn = aresetn;
    assign m1_if.aclk = aclk; assign m1_if.aresetn = aresetn;
    assign s0_if.aclk = aclk; assign s0_if.aresetn = aresetn;
    assign s1_if.aclk = aclk; assign s1_if.aresetn = aresetn;
    assign s2_if.aclk = aclk; assign s2_if.aresetn = aresetn;

    // 3. Map S00_AXI to m0_if
    assign m0_if.awaddr = s00_axi_awaddr; assign m0_if.awid = s00_axi_awid; assign m0_if.awvalid = s00_axi_awvalid; assign s00_axi_awready = m0_if.awready;
    assign m0_if.wdata = s00_axi_wdata; assign m0_if.wstrb = s00_axi_wstrb; assign m0_if.wlast = s00_axi_wlast; assign m0_if.wvalid = s00_axi_wvalid; assign s00_axi_wready = m0_if.wready;
    assign s00_axi_bresp = m0_if.bresp; assign s00_axi_bid = m0_if.bid; assign s00_axi_bvalid = m0_if.bvalid; assign m0_if.bready = s00_axi_bready;
    assign m0_if.araddr = s00_axi_araddr; assign m0_if.arid = s00_axi_arid; assign m0_if.arvalid = s00_axi_arvalid; assign s00_axi_arready = m0_if.arready;
    assign s00_axi_rdata = m0_if.rdata; assign s00_axi_rresp = m0_if.rresp; assign s00_axi_rid = m0_if.rid; assign s00_axi_rlast = m0_if.rlast; assign s00_axi_rvalid = m0_if.rvalid; assign m0_if.rready = s00_axi_rready;

    // 4. Map S01_AXI to m1_if
    assign m1_if.awaddr = s01_axi_awaddr; assign m1_if.awid = s01_axi_awid; assign m1_if.awvalid = s01_axi_awvalid; assign s01_axi_awready = m1_if.awready;
    assign m1_if.wdata = s01_axi_wdata; assign m1_if.wstrb = s01_axi_wstrb; assign m1_if.wlast = s01_axi_wlast; assign m1_if.wvalid = s01_axi_wvalid; assign s01_axi_wready = m1_if.wready;
    assign s01_axi_bresp = m1_if.bresp; assign s01_axi_bid = m1_if.bid; assign s01_axi_bvalid = m1_if.bvalid; assign m1_if.bready = s01_axi_bready;
    assign m1_if.araddr = s01_axi_araddr; assign m1_if.arid = s01_axi_arid; assign m1_if.arvalid = s01_axi_arvalid; assign s01_axi_arready = m1_if.arready;
    assign s01_axi_rdata = m1_if.rdata; assign s01_axi_rresp = m1_if.rresp; assign s01_axi_rid = m1_if.rid; assign s01_axi_rlast = m1_if.rlast; assign s01_axi_rvalid = m1_if.rvalid; assign m1_if.rready = s01_axi_rready;

    // 5. Map M00_AXI from s0_if
    assign m00_axi_awaddr = s0_if.awaddr; assign m00_axi_awid = s0_if.awid; assign m00_axi_awvalid = s0_if.awvalid; assign s0_if.awready = m00_axi_awready;
    assign m00_axi_wdata = s0_if.wdata; assign m00_axi_wstrb = s0_if.wstrb; assign m00_axi_wlast = s0_if.wlast; assign m00_axi_wvalid = s0_if.wvalid; assign s0_if.wready = m00_axi_wready;
    assign s0_if.bresp = m00_axi_bresp; assign s0_if.bid = m00_axi_bid; assign s0_if.bvalid = m00_axi_bvalid; assign m00_axi_bready = s0_if.bready;
    assign m00_axi_araddr = s0_if.araddr; assign m00_axi_arid = s0_if.arid; assign m00_axi_arvalid = s0_if.arvalid; assign s0_if.arready = m00_axi_arready;
    assign s0_if.rdata = m00_axi_rdata; assign s0_if.rresp = m00_axi_rresp; assign s0_if.rid = m00_axi_rid; assign s0_if.rlast = m00_axi_rlast; assign s0_if.rvalid = m00_axi_rvalid; assign m00_axi_rready = s0_if.rready;

    // 6. Map M01_AXI from s1_if
    assign m01_axi_awaddr = s1_if.awaddr; assign m01_axi_awid = s1_if.awid; assign m01_axi_awvalid = s1_if.awvalid; assign s1_if.awready = m01_axi_awready;
    assign m01_axi_wdata = s1_if.wdata; assign m01_axi_wstrb = s1_if.wstrb; assign m01_axi_wlast = s1_if.wlast; assign m01_axi_wvalid = s1_if.wvalid; assign s1_if.wready = m01_axi_wready;
    assign s1_if.bresp = m01_axi_bresp; assign s1_if.bid = m01_axi_bid; assign s1_if.bvalid = m01_axi_bvalid; assign m01_axi_bready = s1_if.bready;
    assign m01_axi_araddr = s1_if.araddr; assign m01_axi_arid = s1_if.arid; assign m01_axi_arvalid = s1_if.arvalid; assign s1_if.arready = m01_axi_arready;
    assign s1_if.rdata = m01_axi_rdata; assign s1_if.rresp = m01_axi_rresp; assign s1_if.rid = m01_axi_rid; assign s1_if.rlast = m01_axi_rlast; assign s1_if.rvalid = m01_axi_rvalid; assign m01_axi_rready = s1_if.rready;

    // 7. Map M02_AXI from s2_if
    assign m02_axi_awaddr = s2_if.awaddr; assign m02_axi_awid = s2_if.awid; assign m02_axi_awvalid = s2_if.awvalid; assign s2_if.awready = m02_axi_awready;
    assign m02_axi_wdata = s2_if.wdata; assign m02_axi_wstrb = s2_if.wstrb; assign m02_axi_wlast = s2_if.wlast; assign m02_axi_wvalid = s2_if.wvalid; assign s2_if.wready = m02_axi_wready;
    assign s2_if.bresp = m02_axi_bresp; assign s2_if.bid = m02_axi_bid; assign s2_if.bvalid = m02_axi_bvalid; assign m02_axi_bready = s2_if.bready;
    assign m02_axi_araddr = s2_if.araddr; assign m02_axi_arid = s2_if.arid; assign m02_axi_arvalid = s2_if.arvalid; assign s2_if.arready = m02_axi_arready;
    assign s2_if.rdata = m02_axi_rdata; assign s2_if.rresp = m02_axi_rresp; assign s2_if.rid = m02_axi_rid; assign s2_if.rlast = m02_axi_rlast; assign s2_if.rvalid = m02_axi_rvalid; assign m02_axi_rready = s2_if.rready;

    // 8. Constant burst attributes on the master side (Option A)
    //    AWLEN  = 0     -> 1 beat per transaction
    //    AWSIZE = 3'b010 -> 4 bytes per beat. MUST be 010 for a 32-bit bus,
    //                       otherwise the BRAM controller treats the access
    //                       as a single byte and the data is wrong/ignored.
    //    AWBURST = 2'b01 -> INCR
    assign m00_axi_awlen   = 8'h00;
    assign m00_axi_awsize  = 3'b010;
    assign m00_axi_awburst = 2'b01;
    assign m00_axi_arlen   = 8'h00;
    assign m00_axi_arsize  = 3'b010;
    assign m00_axi_arburst = 2'b01;

    assign m01_axi_awlen   = 8'h00;
    assign m01_axi_awsize  = 3'b010;
    assign m01_axi_awburst = 2'b01;
    assign m01_axi_arlen   = 8'h00;
    assign m01_axi_arsize  = 3'b010;
    assign m01_axi_arburst = 2'b01;

    assign m02_axi_awlen   = 8'h00;
    assign m02_axi_awsize  = 3'b010;
    assign m02_axi_awburst = 2'b01;
    assign m02_axi_arlen   = 8'h00;
    assign m02_axi_arsize  = 3'b010;
    assign m02_axi_arburst = 2'b01;

    // 8b. Slave-side burst attributes are accepted but not used.
    //     They exist so that IP-XACT classifies s00/s01 as full AXI4 rather
    //     than AXI4-Lite. Without them SmartConnect drives the port as Lite
    //     and WLAST never arrives, which stalls the write data phase.
    //     Option A assumes single-beat accesses, so AWLEN is ignored.
    //     synthesis will optimize these away; the ports still shape the
    //     interface definition.
    wire [7:0] unused_s00_awlen   = s00_axi_awlen;
    wire [2:0] unused_s00_awsize  = s00_axi_awsize;
    wire [1:0] unused_s00_awburst = s00_axi_awburst;
    wire [7:0] unused_s00_arlen   = s00_axi_arlen;
    wire [2:0] unused_s00_arsize  = s00_axi_arsize;
    wire [1:0] unused_s00_arburst = s00_axi_arburst;

    wire [7:0] unused_s01_awlen   = s01_axi_awlen;
    wire [2:0] unused_s01_awsize  = s01_axi_awsize;
    wire [1:0] unused_s01_awburst = s01_axi_awburst;
    wire [7:0] unused_s01_arlen   = s01_axi_arlen;
    wire [2:0] unused_s01_arsize  = s01_axi_arsize;
    wire [1:0] unused_s01_arburst = s01_axi_arburst;
    
    // 9. Instantiate the core RTL module
    axi_interconnect core_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .m0_if(m0_if),
        .m1_if(m1_if),
        .s0_if(s0_if),
        .s1_if(s1_if),
        .s2_if(s2_if)
    );

endmodule