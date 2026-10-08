import uvm_pkg::*;
`include "uvm_macros.svh"

class axi_transaction extends uvm_sequence_item;
    
    // --- Random Variables (The Payload) ---
    rand bit [31:0] addr;      // Address to read/write
    rand bit [31:0] data;      // Data to write (or read data received)
    rand bit [3:0]  id;        // Transaction ID
    rand bit        is_write;  // 1 = Write transaction, 0 = Read transaction
    
    // --- Response Variables ---
    bit [1:0] resp;            // Response from Slave (OKAY, ERROR, etc.)

    // --- UVM Factory Registration ---
    // This macro is mandatory for UVM to recognize this class
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(id,       UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
    `uvm_object_utils_end

    // --- Constructor ---
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

endclass