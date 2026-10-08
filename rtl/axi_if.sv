// -----------------------------------------------------------------------------
// File Name   : axi_if.sv
// Description : AXI4 Full Interface definition 
// -----------------------------------------------------------------------------

interface axi_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4   // Crucial for Out-of-Order execution support
) (
    input logic aclk,
    input logic aresetn
);

    // ------------------------------------
    // 1. Write Address Channel (AW)
    // ------------------------------------
    logic [ID_WIDTH-1:0]   awid;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;

    // ------------------------------------
    // 2. Write Data Channel (W)
    // ------------------------------------
    logic [DATA_WIDTH-1:0] wdata;
    logic [3:0]            wstrb;   // Byte enable
    logic                  wlast;   // <<< new
    logic                  wvalid;
    logic                  wready;

    // ------------------------------------
    // 3. Write Response Channel (B)
    // ------------------------------------
    logic [ID_WIDTH-1:0]   bid;
    logic [1:0]            bresp;   // Status: OKAY, EXOKAY, SLVERR, DECERR
    logic                  bvalid;
    logic                  bready;

    // ------------------------------------
    // 4. Read Address Channel (AR)
    // ------------------------------------
    logic [ID_WIDTH-1:0]   arid;
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;

    // ------------------------------------
    // 5. Read Data Channel (R)
    // ------------------------------------
    logic [ID_WIDTH-1:0]   rid;
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rlast;   // <<< new
    logic                  rvalid;
    logic                  rready;
    
    // ------------------------------------
    // Modports for defining directional I/O
    // ------------------------------------
    modport master (
        output awid, awaddr, awvalid,
        input  awready,
        output wdata, wstrb, wlast, wvalid,     // + wlast
        input  wready,
        input  bid, bresp, bvalid,
        output bready,
        output arid, araddr, arvalid,
        input  arready,
        input  rid, rdata, rresp, rlast, rvalid, // + rlast
        output rready
    );

    modport slave (
        input  awid, awaddr, awvalid,
        output awready,
        input  wdata, wstrb, wlast, wvalid,     // + wlast
        output wready,
        output bid, bresp, bvalid,
        input  bready,
        input  arid, araddr, arvalid,
        output arready,
        output rid, rdata, rresp, rlast, rvalid, // + rlast
        input  rready
    );

endinterface