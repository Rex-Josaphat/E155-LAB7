// Josaphat Ngoga
// jngoga@g.hmc.edu
// 10/15/2025

`timescale 10ns/1ns

/////////////////////////////////////////////
// testbench_shiftRows_tb
// Tests shiftRows module for proper shifting operations.
// Demonstration follows examples from FIPS-197 appendix A.1
/////////////////////////////////////////////

module getNextKey_tb();
    logic clk;
    logic [31:0] rcon;
    logic [3:0][31:0] currKey, nextKey, nextKeyExpected;

    // device under test
    getNextKey dut(clk, currKey, rcon, nextKey);

    // generate clock and load signals
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    initial begin
        currKey <= 128'h2B7E151628AED2A6ABF7158809CF4F3C; 
        rcon <= 32'h01000000; // rcon for first round key
        nextKeyExpected <= 128'hA0FAFE1788542CB123A339392A6C7605; 
        
        @(posedge clk); #1; // S-box cycle delay

        if (nextKey == nextKeyExpected) 
            $display("Testbench ran successfully");
        else
            $display("Error: nextKey = %h, expected %h", nextKey, nextKeyExpected);
        $stop();
    end
endmodule