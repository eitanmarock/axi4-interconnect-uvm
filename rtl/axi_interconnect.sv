// -----------------------------------------------------------------------------
// File Name   : axi_interconnect.sv
// Description : Top level module for AXI4 Interconnect (2 Masters, 3 Slaves)
// RTL
// -----------------------------------------------------------------------------

module axi_interconnect (
    input logic aclk,
    input logic aresetn,

    // Connections to the 2 Masters (Interconnect acts as a Slave to them)
    axi_if.slave m0_if,
    axi_if.slave m1_if,

    // Connections to the 3 Slaves (Interconnect acts as a Master to them)
    axi_if.master s0_if,
    axi_if.master s1_if,
    axi_if.master s2_if
);

    // ------------------------------------
    // Address decode results
    // ------------------------------------
    logic [1:0] target_slave_m0_wr;
    logic [1:0] target_slave_m0_rd;
    logic [1:0] target_slave_m1_wr;
    logic [1:0] target_slave_m1_rd;

    // Arbiter grants (address phase only)
    logic grant_m0_wr, grant_m1_wr;
    logic grant_m0_rd, grant_m1_rd;

    // Default slave response registers
    logic       def_m0_bvalid;
    logic [3:0] def_m0_bid;
    logic       def_m1_bvalid;
    logic [3:0] def_m1_bid;

    logic       def_m0_rvalid;
    logic [3:0] def_m0_rid;
    logic       def_m1_rvalid;
    logic [3:0] def_m1_rid;

    // ------------------------------------
    // Transaction lock registers
    // ------------------------------------
    // wr_lock_active : a write data phase is in progress
    // wr_lock_master : which master owns it (0 = m0, 1 = m1)
    // wr_lock_slave  : which slave it is routed to (3 = default slave)
    logic       wr_lock_active;
    logic       wr_lock_master;
    logic [1:0] wr_lock_slave;

    logic       rd_lock_active;
    logic       rd_lock_master;
    logic [1:0] rd_lock_slave;

    // ------------------------------------
    // Address Decoder Logic
    // ------------------------------------
    always_comb begin
        // Decode Master 0 Write Address
        if (m0_if.awaddr >= 32'h4000_0000 && m0_if.awaddr <= 32'h4000_1FFF) begin
            target_slave_m0_wr = 2'd0; // Route to S0 (BRAM)
        end else if (m0_if.awaddr >= 32'h4001_0000 && m0_if.awaddr <= 32'h4001_FFFF) begin
            target_slave_m0_wr = 2'd1; // Route to S1 (GPIO 1)
        end else if (m0_if.awaddr >= 32'h4002_0000 && m0_if.awaddr <= 32'h4002_FFFF) begin
            target_slave_m0_wr = 2'd2; // Route to S2 (GPIO 2)
        end else begin
            target_slave_m0_wr = 2'd3; // Route to Default Slave
        end

        // Decode Master 1 Write Address
        if (m1_if.awaddr >= 32'h4000_0000 && m1_if.awaddr <= 32'h4000_1FFF) begin
            target_slave_m1_wr = 2'd0;
        end else if (m1_if.awaddr >= 32'h4001_0000 && m1_if.awaddr <= 32'h4001_FFFF) begin
            target_slave_m1_wr = 2'd1;
        end else if (m1_if.awaddr >= 32'h4002_0000 && m1_if.awaddr <= 32'h4002_FFFF) begin
            target_slave_m1_wr = 2'd2;
        end else begin
            target_slave_m1_wr = 2'd3;
        end

        // Decode Master 0 Read Address
        if (m0_if.araddr >= 32'h4000_0000 && m0_if.araddr <= 32'h4000_1FFF) begin
            target_slave_m0_rd = 2'd0;
        end else if (m0_if.araddr >= 32'h4001_0000 && m0_if.araddr <= 32'h4001_FFFF) begin
            target_slave_m0_rd = 2'd1;
        end else if (m0_if.araddr >= 32'h4002_0000 && m0_if.araddr <= 32'h4002_FFFF) begin
            target_slave_m0_rd = 2'd2;
        end else begin
            target_slave_m0_rd = 2'd3;
        end

        // Decode Master 1 Read Address
        if (m1_if.araddr >= 32'h4000_0000 && m1_if.araddr <= 32'h4000_1FFF) begin
            target_slave_m1_rd = 2'd0;
        end else if (m1_if.araddr >= 32'h4001_0000 && m1_if.araddr <= 32'h4001_FFFF) begin
            target_slave_m1_rd = 2'd1;
        end else if (m1_if.araddr >= 32'h4002_0000 && m1_if.araddr <= 32'h4002_FFFF) begin
            target_slave_m1_rd = 2'd2;
        end else begin
            target_slave_m1_rd = 2'd3;
        end
    end

    // ------------------------------------
    // Write Arbiter (address phase)
    // ------------------------------------
    // While a write is locked, no new address is accepted. This keeps the
    // design simple: one outstanding write at a time.
    logic last_grant_wr;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            last_grant_wr <= 1'b1;
        end else begin
            if (grant_m0_wr && m0_if.awvalid && m0_if.awready) begin
                last_grant_wr <= 1'b0;
            end else if (grant_m1_wr && m1_if.awvalid && m1_if.awready) begin
                last_grant_wr <= 1'b1;
            end
        end
    end

    always_comb begin
        grant_m0_wr = 1'b0;
        grant_m1_wr = 1'b0;

        if (!wr_lock_active) begin
            if (m0_if.awvalid && m1_if.awvalid) begin
                // Both masters requesting: round robin
                if (last_grant_wr == 1'b1) begin
                    grant_m0_wr = 1'b1;
                end else begin
                    grant_m1_wr = 1'b1;
                end
            end else if (m0_if.awvalid) begin
                grant_m0_wr = 1'b1;
            end else if (m1_if.awvalid) begin
                grant_m1_wr = 1'b1;
            end
        end
    end

    // ------------------------------------
    // Read Arbiter (address phase)
    // ------------------------------------
    logic last_grant_rd;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            last_grant_rd <= 1'b1;
        end else begin
            if (grant_m0_rd && m0_if.arvalid && m0_if.arready) begin
                last_grant_rd <= 1'b0;
            end else if (grant_m1_rd && m1_if.arvalid && m1_if.arready) begin
                last_grant_rd <= 1'b1;
            end
        end
    end

    always_comb begin
        grant_m0_rd = 1'b0;
        grant_m1_rd = 1'b0;

        if (!rd_lock_active) begin
            if (m0_if.arvalid && m1_if.arvalid) begin
                if (last_grant_rd == 1'b1) begin
                    grant_m0_rd = 1'b1;
                end else begin
                    grant_m1_rd = 1'b1;
                end
            end else if (m0_if.arvalid) begin
                grant_m0_rd = 1'b1;
            end else if (m1_if.arvalid) begin
                grant_m1_rd = 1'b1;
            end
        end
    end

    // ------------------------------------
    // Lock acquire / release
    // ------------------------------------
    // Helper wires describing the currently locked write data beat
    logic wr_beat_done;   // last data beat accepted on the locked path
    logic rd_beat_done;   // last read beat accepted on the locked path

    // Which W-channel signals are visible to the locked slave
    logic        lk_wvalid;
    logic [31:0] lk_wdata;
    logic [3:0]  lk_wstrb;
    logic        lk_wlast;
    logic        lk_wready;

    always_comb begin
        if (wr_lock_active && (wr_lock_master == 1'b0)) begin
            lk_wvalid = m0_if.wvalid;
            lk_wdata  = m0_if.wdata;
            lk_wstrb  = m0_if.wstrb;
            lk_wlast  = m0_if.wlast;
        end else if (wr_lock_active && (wr_lock_master == 1'b1)) begin
            lk_wvalid = m1_if.wvalid;
            lk_wdata  = m1_if.wdata;
            lk_wstrb  = m1_if.wstrb;
            lk_wlast  = m1_if.wlast;
        end else begin
            lk_wvalid = 1'b0;
            lk_wdata  = '0;
            lk_wstrb  = '0;
            lk_wlast  = 1'b0;
        end
    end

    // WREADY seen by the locked master, taken from the locked slave
    always_comb begin
        case (wr_lock_slave)
            2'd0:    lk_wready = s0_if.wready;
            2'd1:    lk_wready = s1_if.wready;
            2'd2:    lk_wready = s2_if.wready;
            default: lk_wready = 1'b1;          // default slave always accepts
        endcase
    end

    assign wr_beat_done = wr_lock_active && lk_wvalid && lk_wready && lk_wlast;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            wr_lock_active <= 1'b0;
            wr_lock_master <= 1'b0;
            wr_lock_slave  <= 2'd0;
        end else begin
            if (!wr_lock_active) begin
                // Take the lock on the AW handshake
                if (grant_m0_wr && m0_if.awvalid && m0_if.awready) begin
                    wr_lock_active <= 1'b1;
                    wr_lock_master <= 1'b0;
                    wr_lock_slave  <= target_slave_m0_wr;
                end else if (grant_m1_wr && m1_if.awvalid && m1_if.awready) begin
                    wr_lock_active <= 1'b1;
                    wr_lock_master <= 1'b1;
                    wr_lock_slave  <= target_slave_m1_wr;
                end
            end else if (wr_beat_done) begin
                // Release once the final data beat has been accepted
                wr_lock_active <= 1'b0;
            end
        end
    end

    // Read lock: released when the last read beat reaches the master
    logic lk_rvalid_to_master;
    logic lk_rlast_to_master;
    logic lk_rready_from_master;

    always_comb begin
        case (rd_lock_slave)
            2'd0: begin lk_rvalid_to_master = s0_if.rvalid; lk_rlast_to_master = s0_if.rlast; end
            2'd1: begin lk_rvalid_to_master = s1_if.rvalid; lk_rlast_to_master = s1_if.rlast; end
            2'd2: begin lk_rvalid_to_master = s2_if.rvalid; lk_rlast_to_master = s2_if.rlast; end
            default: begin
                // Default slave: the error response is generated internally
                lk_rvalid_to_master = (rd_lock_master == 1'b0) ? def_m0_rvalid : def_m1_rvalid;
                lk_rlast_to_master  = 1'b1;
            end
        endcase

        lk_rready_from_master = (rd_lock_master == 1'b0) ? m0_if.rready : m1_if.rready;
    end

    assign rd_beat_done = rd_lock_active && lk_rvalid_to_master &&
                          lk_rready_from_master && lk_rlast_to_master;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rd_lock_active <= 1'b0;
            rd_lock_master <= 1'b0;
            rd_lock_slave  <= 2'd0;
        end else begin
            if (!rd_lock_active) begin
                if (grant_m0_rd && m0_if.arvalid && m0_if.arready) begin
                    rd_lock_active <= 1'b1;
                    rd_lock_master <= 1'b0;
                    rd_lock_slave  <= target_slave_m0_rd;
                end else if (grant_m1_rd && m1_if.arvalid && m1_if.arready) begin
                    rd_lock_active <= 1'b1;
                    rd_lock_master <= 1'b1;
                    rd_lock_slave  <= target_slave_m1_rd;
                end
            end else if (rd_beat_done) begin
                rd_lock_active <= 1'b0;
            end
        end
    end

    // ------------------------------------
    // Forward Path - S0
    // ------------------------------------
    always_comb begin
        s0_if.awvalid = 1'b0; s0_if.awaddr = '0; s0_if.awid = '0;
        s0_if.wvalid  = 1'b0; s0_if.wdata  = '0; s0_if.wstrb = '0; s0_if.wlast = 1'b0;
        s0_if.arvalid = 1'b0; s0_if.araddr = '0; s0_if.arid = '0;

        // AW channel: driven by the arbiter grant (address phase)
        if (grant_m0_wr && (target_slave_m0_wr == 2'd0)) begin
            s0_if.awvalid = m0_if.awvalid;
            s0_if.awaddr  = m0_if.awaddr;
            s0_if.awid    = {1'b0, m0_if.awid[2:0]};
        end else if (grant_m1_wr && (target_slave_m1_wr == 2'd0)) begin
            s0_if.awvalid = m1_if.awvalid;
            s0_if.awaddr  = m1_if.awaddr;
            s0_if.awid    = {1'b1, m1_if.awid[2:0]};
        end

        // W channel: driven by the LOCK, independent of AWVALID
        if (wr_lock_active && (wr_lock_slave == 2'd0)) begin
            s0_if.wvalid = lk_wvalid;
            s0_if.wdata  = lk_wdata;
            s0_if.wstrb  = lk_wstrb;
            s0_if.wlast  = lk_wlast;
        end

        // AR channel
        if (grant_m0_rd && (target_slave_m0_rd == 2'd0)) begin
            s0_if.arvalid = m0_if.arvalid;
            s0_if.araddr  = m0_if.araddr;
            s0_if.arid    = {1'b0, m0_if.arid[2:0]};
        end else if (grant_m1_rd && (target_slave_m1_rd == 2'd0)) begin
            s0_if.arvalid = m1_if.arvalid;
            s0_if.araddr  = m1_if.araddr;
            s0_if.arid    = {1'b1, m1_if.arid[2:0]};
        end
    end

    // ------------------------------------
    // Forward Path - S1
    // ------------------------------------
    always_comb begin
        s1_if.awvalid = 1'b0; s1_if.awaddr = '0; s1_if.awid = '0;
        s1_if.wvalid  = 1'b0; s1_if.wdata  = '0; s1_if.wstrb = '0; s1_if.wlast = 1'b0;
        s1_if.arvalid = 1'b0; s1_if.araddr = '0; s1_if.arid = '0;

        if (grant_m0_wr && (target_slave_m0_wr == 2'd1)) begin
            s1_if.awvalid = m0_if.awvalid;
            s1_if.awaddr  = m0_if.awaddr;
            s1_if.awid    = {1'b0, m0_if.awid[2:0]};
        end else if (grant_m1_wr && (target_slave_m1_wr == 2'd1)) begin
            s1_if.awvalid = m1_if.awvalid;
            s1_if.awaddr  = m1_if.awaddr;
            s1_if.awid    = {1'b1, m1_if.awid[2:0]};
        end

        if (wr_lock_active && (wr_lock_slave == 2'd1)) begin
            s1_if.wvalid = lk_wvalid;
            s1_if.wdata  = lk_wdata;
            s1_if.wstrb  = lk_wstrb;
            s1_if.wlast  = lk_wlast;
        end

        if (grant_m0_rd && (target_slave_m0_rd == 2'd1)) begin
            s1_if.arvalid = m0_if.arvalid;
            s1_if.araddr  = m0_if.araddr;
            s1_if.arid    = {1'b0, m0_if.arid[2:0]};
        end else if (grant_m1_rd && (target_slave_m1_rd == 2'd1)) begin
            s1_if.arvalid = m1_if.arvalid;
            s1_if.araddr  = m1_if.araddr;
            s1_if.arid    = {1'b1, m1_if.arid[2:0]};
        end
    end

    // ------------------------------------
    // Forward Path - S2
    // ------------------------------------
    always_comb begin
        s2_if.awvalid = 1'b0; s2_if.awaddr = '0; s2_if.awid = '0;
        s2_if.wvalid  = 1'b0; s2_if.wdata  = '0; s2_if.wstrb = '0; s2_if.wlast = 1'b0;
        s2_if.arvalid = 1'b0; s2_if.araddr = '0; s2_if.arid = '0;

        if (grant_m0_wr && (target_slave_m0_wr == 2'd2)) begin
            s2_if.awvalid = m0_if.awvalid;
            s2_if.awaddr  = m0_if.awaddr;
            s2_if.awid    = {1'b0, m0_if.awid[2:0]};
        end else if (grant_m1_wr && (target_slave_m1_wr == 2'd2)) begin
            s2_if.awvalid = m1_if.awvalid;
            s2_if.awaddr  = m1_if.awaddr;
            s2_if.awid    = {1'b1, m1_if.awid[2:0]};
        end

        if (wr_lock_active && (wr_lock_slave == 2'd2)) begin
            s2_if.wvalid = lk_wvalid;
            s2_if.wdata  = lk_wdata;
            s2_if.wstrb  = lk_wstrb;
            s2_if.wlast  = lk_wlast;
        end

        if (grant_m0_rd && (target_slave_m0_rd == 2'd2)) begin
            s2_if.arvalid = m0_if.arvalid;
            s2_if.araddr  = m0_if.araddr;
            s2_if.arid    = {1'b0, m0_if.arid[2:0]};
        end else if (grant_m1_rd && (target_slave_m1_rd == 2'd2)) begin
            s2_if.arvalid = m1_if.arvalid;
            s2_if.araddr  = m1_if.araddr;
            s2_if.arid    = {1'b1, m1_if.arid[2:0]};
        end
    end

    // ------------------------------------
    // Backward Path - B Channel (Write Response)
    // ------------------------------------
    always_comb begin
        m0_if.bvalid = 1'b0; m0_if.bid = '0; m0_if.bresp = '0;
        m1_if.bvalid = 1'b0; m1_if.bid = '0; m1_if.bresp = '0;
        s0_if.bready = 1'b0; s1_if.bready = 1'b0; s2_if.bready = 1'b0;

        if (def_m0_bvalid) begin
            m0_if.bvalid = 1'b1; m0_if.bid = def_m0_bid; m0_if.bresp = 2'b11;
        end else if (def_m1_bvalid) begin
            m1_if.bvalid = 1'b1; m1_if.bid = def_m1_bid; m1_if.bresp = 2'b11;
        end else if (s0_if.bvalid) begin
            if (s0_if.bid[3] == 1'b0) begin
                m0_if.bvalid = 1'b1; m0_if.bid = s0_if.bid; m0_if.bresp = s0_if.bresp;
                s0_if.bready = m0_if.bready;
            end else begin
                m1_if.bvalid = 1'b1; m1_if.bid = s0_if.bid; m1_if.bresp = s0_if.bresp;
                s0_if.bready = m1_if.bready;
            end
        end else if (s1_if.bvalid) begin
            if (s1_if.bid[3] == 1'b0) begin
                m0_if.bvalid = 1'b1; m0_if.bid = s1_if.bid; m0_if.bresp = s1_if.bresp;
                s1_if.bready = m0_if.bready;
            end else begin
                m1_if.bvalid = 1'b1; m1_if.bid = s1_if.bid; m1_if.bresp = s1_if.bresp;
                s1_if.bready = m1_if.bready;
            end
        end else if (s2_if.bvalid) begin
            if (s2_if.bid[3] == 1'b0) begin
                m0_if.bvalid = 1'b1; m0_if.bid = s2_if.bid; m0_if.bresp = s2_if.bresp;
                s2_if.bready = m0_if.bready;
            end else begin
                m1_if.bvalid = 1'b1; m1_if.bid = s2_if.bid; m1_if.bresp = s2_if.bresp;
                s2_if.bready = m1_if.bready;
            end
        end
    end

    // ------------------------------------
    // Backward Path - R Channel (Read Data)
    // ------------------------------------
    always_comb begin
        m0_if.rvalid = 1'b0; m0_if.rid = '0; m0_if.rdata = '0; m0_if.rresp = '0; m0_if.rlast = 1'b0;
        m1_if.rvalid = 1'b0; m1_if.rid = '0; m1_if.rdata = '0; m1_if.rresp = '0; m1_if.rlast = 1'b0;
        s0_if.rready = 1'b0; s1_if.rready = 1'b0; s2_if.rready = 1'b0;

        if (def_m0_rvalid) begin
            m0_if.rvalid = 1'b1; m0_if.rid = def_m0_rid; m0_if.rdata = 32'hDEADDEAD;
            m0_if.rresp  = 2'b11; m0_if.rlast = 1'b1;
        end else if (def_m1_rvalid) begin
            m1_if.rvalid = 1'b1; m1_if.rid = def_m1_rid; m1_if.rdata = 32'hDEADDEAD;
            m1_if.rresp  = 2'b11; m1_if.rlast = 1'b1;
        end else if (s0_if.rvalid) begin
            if (s0_if.rid[3] == 1'b0) begin
                m0_if.rvalid = 1'b1; m0_if.rid = s0_if.rid; m0_if.rdata = s0_if.rdata;
                m0_if.rresp  = s0_if.rresp; m0_if.rlast = s0_if.rlast;
                s0_if.rready = m0_if.rready;
            end else begin
                m1_if.rvalid = 1'b1; m1_if.rid = s0_if.rid; m1_if.rdata = s0_if.rdata;
                m1_if.rresp  = s0_if.rresp; m1_if.rlast = s0_if.rlast;
                s0_if.rready = m1_if.rready;
            end
        end else if (s1_if.rvalid) begin
            if (s1_if.rid[3] == 1'b0) begin
                m0_if.rvalid = 1'b1; m0_if.rid = s1_if.rid; m0_if.rdata = s1_if.rdata;
                m0_if.rresp  = s1_if.rresp; m0_if.rlast = s1_if.rlast;
                s1_if.rready = m0_if.rready;
            end else begin
                m1_if.rvalid = 1'b1; m1_if.rid = s1_if.rid; m1_if.rdata = s1_if.rdata;
                m1_if.rresp  = s1_if.rresp; m1_if.rlast = s1_if.rlast;
                s1_if.rready = m1_if.rready;
            end
        end else if (s2_if.rvalid) begin
            if (s2_if.rid[3] == 1'b0) begin
                m0_if.rvalid = 1'b1; m0_if.rid = s2_if.rid; m0_if.rdata = s2_if.rdata;
                m0_if.rresp  = s2_if.rresp; m0_if.rlast = s2_if.rlast;
                s2_if.rready = m0_if.rready;
            end else begin
                m1_if.rvalid = 1'b1; m1_if.rid = s2_if.rid; m1_if.rdata = s2_if.rdata;
                m1_if.rresp  = s2_if.rresp; m1_if.rlast = s2_if.rlast;
                s2_if.rready = m1_if.rready;
            end
        end
    end

    // ------------------------------------
    // Internal Default Slave Logic
    // ------------------------------------
    // Write: respond once the locked write data beat has been consumed.
    // Read : respond once the address has been accepted.
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            def_m0_bvalid <= 1'b0; def_m0_bid <= '0;
            def_m1_bvalid <= 1'b0; def_m1_bid <= '0;
            def_m0_rvalid <= 1'b0; def_m0_rid <= '0;
            def_m1_rvalid <= 1'b0; def_m1_rid <= '0;
        end else begin
            // Write response, master 0
            if (wr_lock_active && (wr_lock_slave == 2'd3) && (wr_lock_master == 1'b0) &&
                lk_wvalid && lk_wlast) begin
                def_m0_bvalid <= 1'b1;
                def_m0_bid    <= m0_if.awid;
            end else if (def_m0_bvalid && m0_if.bready) begin
                def_m0_bvalid <= 1'b0;
            end

            // Write response, master 1
            if (wr_lock_active && (wr_lock_slave == 2'd3) && (wr_lock_master == 1'b1) &&
                lk_wvalid && lk_wlast) begin
                def_m1_bvalid <= 1'b1;
                def_m1_bid    <= m1_if.awid;
            end else if (def_m1_bvalid && m1_if.bready) begin
                def_m1_bvalid <= 1'b0;
            end

            // Read response, master 0
            if (grant_m0_rd && (target_slave_m0_rd == 2'd3) && m0_if.arvalid) begin
                def_m0_rvalid <= 1'b1;
                def_m0_rid    <= m0_if.arid;
            end else if (def_m0_rvalid && m0_if.rready) begin
                def_m0_rvalid <= 1'b0;
            end

            // Read response, master 1
            if (grant_m1_rd && (target_slave_m1_rd == 2'd3) && m1_if.arvalid) begin
                def_m1_rvalid <= 1'b1;
                def_m1_rid    <= m1_if.arid;
            end else if (def_m1_rvalid && m1_if.rready) begin
                def_m1_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------
    // Ready Signals Routing
    // ------------------------------------
    // AWREADY / ARREADY follow the arbiter grant (address phase).
    // WREADY follows the LOCK, so the data phase survives AWVALID dropping.
    always_comb begin
        m0_if.awready = 1'b0; m0_if.wready = 1'b0; m0_if.arready = 1'b0;
        m1_if.awready = 1'b0; m1_if.wready = 1'b0; m1_if.arready = 1'b0;

        // AWREADY - depends on the lock state only, NOT on AWVALID.
        // A combinational path from the master's AWVALID back to its AWREADY
        // can deadlock against SmartConnect, which may build its own AWVALID
        // from the AWREADY it sees.
        if (!wr_lock_active) begin
            case (target_slave_m0_wr)
                2'd0:    m0_if.awready = s0_if.awready;
                2'd1:    m0_if.awready = s1_if.awready;
                2'd2:    m0_if.awready = s2_if.awready;
                default: m0_if.awready = 1'b1;
            endcase

            case (target_slave_m1_wr)
                2'd0:    m1_if.awready = s0_if.awready;
                2'd1:    m1_if.awready = s1_if.awready;
                2'd2:    m1_if.awready = s2_if.awready;
                default: m1_if.awready = 1'b1;
            endcase
        end
        
        // WREADY, from the locked slave to the locked master only
        if (wr_lock_active) begin
            if (wr_lock_master == 1'b0) begin
                m0_if.wready = lk_wready;
            end else begin
                m1_if.wready = lk_wready;
            end
        end

        // ARREADY - same reasoning as AWREADY above
        if (!rd_lock_active) begin
            case (target_slave_m0_rd)
                2'd0:    m0_if.arready = s0_if.arready;
                2'd1:    m0_if.arready = s1_if.arready;
                2'd2:    m0_if.arready = s2_if.arready;
                default: m0_if.arready = 1'b1;
            endcase

            case (target_slave_m1_rd)
                2'd0:    m1_if.arready = s0_if.arready;
                2'd1:    m1_if.arready = s1_if.arready;
                2'd2:    m1_if.arready = s2_if.arready;
                default: m1_if.arready = 1'b1;
            endcase
        end
    end
        
endmodule