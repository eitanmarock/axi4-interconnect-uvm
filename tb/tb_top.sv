import uvm_pkg::*;
`include "uvm_macros.svh"

`include "axi_pkg.sv"
import axi_pkg::*;

// Note: This is a MODULE, not a class! It represents static hardware.
module tb_top;

    // 1. Clock and Reset Signals
    logic aclk;
    logic aresetn; // 'n' means active-low (reset when 0)

    // 2. Generate Clock (e.g., 100MHz -> 10ns period)
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // Toggle every 5 time units
    end

    // 3. Generate Reset
    initial begin
        aresetn = 0; // Start in reset mode
        #20;         // Wait for 20 time units
        aresetn = 1; // Release the reset (turn on the system)
    end

    // 4. Instantiate the physical wires (The Interface)
    axi_if vif(aclk, aresetn);

    // 5. Instantiate the Hardware (DUT - Design Under Test)
    // Instantiating the wrapper and connecting our UVM interface (vif) to Master 0 (s00)
    axi_interconnect_wrapper dut (
        .aclk(aclk),
        .aresetn(aresetn),

        // --- Master 0 (S00) Write Address (AW) Channel Connection ---
        .s00_axi_awaddr  (vif.awaddr),
        .s00_axi_awid    (vif.awid),
        .s00_axi_awvalid (vif.awvalid),
        .s00_axi_awready (vif.awready)
        
        // Note: If other channels (W, B, AR, R) are defined in axi_if, 
        // they should be mapped here respectively. Unconnected pins will 
        // generate warnings but will not stop elaboration.
    );

    // 6. The Bridge: Connecting Hardware to UVM and starting the test!
    initial begin
        // Pass the physical interface to the software side using the UVM Database
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", vif);
        
        // Turn the key in the ignition - Start the UVM Test!
        run_test("axi_test");
    end

endmodule