// Josaphat Ngoga
// jngoga@g.hmc.edu
// 10/15/2025

`timescale 10ns/1ns

/////////////////////////////////////////////
// testbench_addRoundKey_tb
// Tests addRoundKey module for proper bitwise XOR operation.
/////////////////////////////////////////////

module addRoundKey_tb();
    logic [127:0] a, y, yExpected;
    logic [3:0][31:0] k;

    addRoundKey dut(a, k, y);

    initial begin
        a <= 128'h3243F6A8885A308D313198A2E0370734;
        k <= 128'h2B7E151628AED2A6ABF7158809CF4F3C;

        yExpected <= 128'h193DE3BEA0F4E22B9AC68D2AE9F84808; #5;
        
        if (y == yExpected) 
            $display("Testbench ran successfully");
        else
            $display("Error: y = %h, expected %h", y, yExpected);
        $stop();
    end
endmodule