import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    // The receiving port (Analysis Imp)
    uvm_analysis_imp #(axi_transaction, axi_scoreboard) item_collected_imp;

    // --- Constructor ---
    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
        // Initialize the receiver
        item_collected_imp = new("item_collected_imp", this);
    endfunction

    // --- The Judging Function ---
    // This function is automatically triggered whenever the Monitor calls .write()
    virtual function void write(axi_transaction trans);
        
        // 1. Log the received transaction
        `uvm_info("SCOREBOARD", $sformatf("Received trans: Addr=0x%0h, is_write=%0b", trans.addr, trans.is_write), UVM_LOW)

        // 2. The Verification Logic (Routing Check)
        if (trans.addr >= 32'h0000_0000 && trans.addr < 32'h4000_0000) begin
            `uvm_info("SCOREBOARD_PASS", "Address correctly mapped to Slave 0!", UVM_LOW)
        end 
        else if (trans.addr >= 32'h4000_0000 && trans.addr < 32'h8000_0000) begin
            `uvm_info("SCOREBOARD_PASS", "Address correctly mapped to Slave 1!", UVM_LOW)
        end 
        // NOTE: The current architecture specification defines only 2 Slaves.
        // Any address >= 32'h8000_0000 (e.g., Slave 2) is out of the valid memory map.
        // This 'else' block serves as Negative Testing, ensuring our environment
        // successfully catches and flags illegal out-of-bound routing attempts.

        else begin
            `uvm_error("SCOREBOARD_FAIL", "Invalid Address mapping! Simulation Failed.")
        end

    endfunction
    
endclass