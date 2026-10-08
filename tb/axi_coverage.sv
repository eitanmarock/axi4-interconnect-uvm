`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axi_coverage)

    axi_transaction trans;

    // --- Covergroups Definition ---
    covergroup axi_cg;
        
        // 1. Routing Coverage: Check access to all slaves and illegal addresses
        cp_address: coverpoint trans.addr {
            bins slave_0_hits = {[32'h0000_0000 : 32'h3FFF_FFFF]};
            bins slave_1_hits = {[32'h4000_0000 : 32'h7FFF_FFFF]};
            bins illegal_hits = {[32'h8000_0000 : 32'hFFFF_FFFF]};
        }
        
        // 2. Operation Type Coverage: Check both Read and Write operations
        cp_direction: coverpoint trans.is_write {
            bins write_op = {1};
            bins read_op  = {0};
        }
        
        // 3. Cross Coverage: Ensure Read and Write to EVERY slave
        cross_addr_dir: cross cp_address, cp_direction;
        
    endgroup

    // --- Constructor ---
    function new(string name = "axi_coverage", uvm_component parent = null);
        super.new(name, parent);
        axi_cg = new(); 
    endfunction

    // --- Write Function (Triggered by Monitor via Analysis Port) ---
    virtual function void write(axi_transaction t);
        trans = t;
        axi_cg.sample(); 
    endfunction

endclass