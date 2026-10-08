import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    // 1. Declare the components (The Lego blocks)
    uvm_sequencer #(axi_transaction) sequencer;
    axi_driver                       driver;
    axi_monitor                      monitor;
    axi_scoreboard                   scoreboard;
    axi_coverage                     coverage_collector;
    
    // --- Constructor ---
    function new(string name = "axi_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    // --- Build Phase: Creating the objects ---
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Create the ready-made Sequencer directly from UVM
        sequencer  = uvm_sequencer#(axi_transaction)::type_id::create("sequencer", this);
        // --- Create the Coverage Collector ---
        coverage_collector = axi_coverage::type_id::create("coverage_collector", this);
        
        // Create our custom components using the Factory
        driver     = axi_driver::type_id::create("driver", this);
        monitor    = axi_monitor::type_id::create("monitor", this);
        scoreboard = axi_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // --- Connect Phase: Wiring them up! ---
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // A. Connect Driver to Sequencer (The task pipeline)
        driver.seq_item_port.connect(sequencer.seq_item_export);
        
        // B. Connect Monitor to Scoreboard (The reporting pipeline)
        monitor.item_collected_port.connect(scoreboard.item_collected_imp);
        
        // C. Connect Monitor to Coverage Collector (Broadcasting)
        monitor.item_collected_port.connect(coverage_collector.analysis_export);
        
    endfunction

endclass