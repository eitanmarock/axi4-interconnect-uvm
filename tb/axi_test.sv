import uvm_pkg::*;
`include "uvm_macros.svh"

// ==========================================
// 1. The Script (Sequence)
// ==========================================
class axi_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info("SEQ", "Starting AXI Sequence generation...", UVM_LOW)
        
        // Loop to generate 10 random transactions
        repeat(10) begin
            req = axi_transaction::type_id::create("req");
            
            start_item(req); // Request permission from Sequencer
            
            if (!req.randomize()) begin // Roll the dice!
                `uvm_error("SEQ", "Randomization failed!")
            end
            
            finish_item(req); // Send it to the Driver
        end
        
        `uvm_info("SEQ", "Finished AXI Sequence.", UVM_LOW)
    endtask
endclass

// ==========================================
// 2. The Main Test Component
// ==========================================
class axi_test extends uvm_test;
    `uvm_component_utils(axi_test)

    axi_env env; // Our Lego baseboard

    function new(string name = "axi_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Build the entire environment
        env = axi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi_sequence seq;
        seq = axi_sequence::type_id::create("seq");
        
        // 1. Tell UVM: "Don't stop the simulation yet, I'm working!"
        phase.raise_objection(this);
        
        // 2. Start throwing the 10 transactions into our Sequencer
        seq.start(env.sequencer);    
        
        // 3. Tell UVM: "I'm done, you can end the simulation now."
        phase.drop_objection(this);  
    endtask
    
endclass