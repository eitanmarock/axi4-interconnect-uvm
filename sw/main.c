#include <stdio.h>
#include "xparameters.h"
#include "xil_printf.h"
#include "xil_io.h"

// Define the exact base addresses for all Slaves
#define AXI_BRAM_BASE_ADDR 0x40000000 // Slave 0: BRAM
#define AXI_SWS_BASE_ADDR  0x40010000 // Slave 1: GPIO_0 (Switches)
#define AXI_LEDS_BASE_ADDR 0x40020000 // Slave 2: GPIO_1 (LEDs)

// AXI GPIO Register Offsets
#define GPIO_DATA_OFFSET 0x0
#define GPIO_TRI_OFFSET  0x4

int main() {
    xil_printf("\r\n============================================\r\n");
    xil_printf("   AXI4 Custom Interconnect - Full System Test\r\n");
    xil_printf("============================================\r\n");

    // --------------------------------------------------------
    // PART 1: BRAM Read/Write Integrity Test
    // --------------------------------------------------------
    xil_printf("\r\n[PART 1] Testing BRAM Data Integrity...\r\n");
    
    u32 write_data = 0xDEADBEEF;
    u32 read_data  = 0x0;

    xil_printf("Writing 0x%08X to BRAM at 0x%08X...\r\n", write_data, AXI_BRAM_BASE_ADDR);
    Xil_Out32(AXI_BRAM_BASE_ADDR, write_data);

    read_data = Xil_In32(AXI_BRAM_BASE_ADDR);
    xil_printf("Read back 0x%08X from BRAM\r\n", read_data);

    if (read_data == write_data) {
        xil_printf(">>> SUCCESS: BRAM Test Passed! <<<\r\n");
    } else {
        xil_printf(">>> ERROR: Data mismatch in BRAM! <<<\r\n");
    }

    // --------------------------------------------------------
    // PART 2: GPIO Switches to LEDs Loop
    // --------------------------------------------------------
    xil_printf("\r\n[PART 2] Starting GPIO Loop...\r\n");
    
    // Configure Tri-State Registers (0 = Output, 1 = Input)
    Xil_Out32(AXI_LEDS_BASE_ADDR + GPIO_TRI_OFFSET, 0x0);          // LEDs as Output
    Xil_Out32(AXI_SWS_BASE_ADDR + GPIO_TRI_OFFSET,  0xFFFFFFFF);   // Switches as Input

    xil_printf("Move the switches on your PYNQ-Z2 board. The LEDs will follow!\r\n");

    u32 switch_state = 0;

    // Infinite loop to read switches and write to LEDs
    while(1) {
        switch_state = Xil_In32(AXI_SWS_BASE_ADDR + GPIO_DATA_OFFSET);
        Xil_Out32(AXI_LEDS_BASE_ADDR + GPIO_DATA_OFFSET, switch_state);
    }

    return 0;
}