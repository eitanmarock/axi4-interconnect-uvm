import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_driver)

    // Virtual Interface - Pointer to the physical signals
    virtual axi_if vif;

    // --- Constructor ---
    function new(string name = "axi_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    // --- Build Phase: Getting the interface ---
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Fetch the physical interface from the UVM database
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found!")
        end
    endfunction

    // --- Run Phase: The main loop ---
    task run_phase(uvm_phase phase);
        forever begin
            // 1. Get the next transaction from the sequencer
            seq_item_port.get_next_item(req);
            
            // 2. Drive the transaction to the hardware
            drive_transaction(req);
            
            // 3. Report completion
            seq_item_port.item_done();
        end
    endtask
    
    // --- The actual physical driving ---
    task drive_transaction(axi_transaction req);
        @(posedge vif.aclk); // Wait for clock edge
        
        if (req.is_write) begin
            // --- Write Transaction (AW & W) ---
            vif.awaddr  <= req.addr;
            vif.awid    <= req.id;
            vif.awvalid <= 1'b1;
            
            vif.wdata   <= req.data;
            vif.wvalid  <= 1'b1;
            
            // Wait for the Interconnect to be ready
            wait(vif.awready && vif.wready);
            @(posedge vif.aclk);
            
            // Deassert valid signals
            vif.awvalid <= 1'b0;
            vif.wvalid  <= 1'b0;
        end else begin
            // --- Read Transaction (AR) ---
            vif.araddr  <= req.addr;
            vif.arid    <= req.id;
            vif.arvalid <= 1'b1;
            
            // Wait for ready signal
            wait(vif.arready);
            @(posedge vif.aclk);
            
            // Deassert valid signal
            vif.arvalid <= 1'b0;
        end
    endtask
    
endclass