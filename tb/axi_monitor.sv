import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_monitor)

    // Virtual Interface - strictly for observing signals
    virtual axi_if vif;

    // Analysis Port - The "broadcaster" to send data to the scoreboard
    uvm_analysis_port #(axi_transaction) item_collected_port;

    // --- Constructor ---
    function new(string name = "axi_monitor", uvm_component parent);
        super.new(name, parent);
        // Initialize the broadcaster
        item_collected_port = new("item_collected_port", this);
    endfunction

    // --- Build Phase ---
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Fetch the interface from the UVM database 
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in Monitor!")
        end
    endfunction

    // --- Run Phase: Passive Observation ---
    task run_phase(uvm_phase phase);
        axi_transaction trans; // Temporary variable to hold captured data
        
        forever begin
            @(posedge vif.aclk); // Wait for clock edge

            // Check for a valid Write Address handshake
            if (vif.awvalid && vif.awready) begin
                
                // 1. Create a fresh transaction object using the Factory
                trans = axi_transaction::type_id::create("trans");
                
                // 2. Extract values from hardware pins into the software object
                trans.is_write = 1'b1;
                trans.addr     = vif.awaddr;
                trans.id       = vif.awid;
                
                // 3. Broadcast the captured transaction to the rest of the system
                item_collected_port.write(trans);
            end
            
            // --- Check for a valid Read Address handshake ---
            if (vif.arvalid && vif.arready) begin
                
                // 1. Create a fresh transaction object for the read
                trans = axi_transaction::type_id::create("trans_read");
                
                // 2. Extract values from hardware pins (Notice it's 'ar' now)
                trans.is_write = 1'b0; // 0 means Read!
                trans.addr     = vif.araddr;
                trans.id       = vif.arid;
                
                // 3. Broadcast the captured transaction
                item_collected_port.write(trans);
            end
        end
    endtask
    
endclass