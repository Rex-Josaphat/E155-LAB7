// Josaphat Ngoga
// jngoga@g.hmc.edu
// 10/15/2025

`timescale 10ns/1ns

/////////////////////////////////////////////
// testbench_subBytes_tb
// Tests subBytes module for proper byte substitution
/////////////////////////////////////////////

module subBytes_tb();
    logic clk;
    logic [127:0] a, y, yExpected;
    logic pass = 1'b1; // indicates if test passed

    // device under test
    subBytes dut(clk, a, y);

    // generate clock and load signals
    always begin
		clk = 1'b0; #5;
		clk = 1'b1; #5;
    end

    // check plaintext examples from FIPS-197 appendix
    initial begin
        a <= 128'h3243F6A8885A308D313198A2E0370734;
        yExpected <= 128'h231A42C2C4BE045DC7C7463AE19AC518;
        @(posedge clk); #1;
        pass &= (y == yExpected);

        a <= 128'h00112233445566778899AABBCCDDEEFF;
        yExpected <= 128'h638293C31BFC33F5C4EEACEA4BC12816;
        @(posedge clk); #1;
        pass &= (y == yExpected);

        if (pass) 
            $display("All test cases ran succesfully");
        else 
            $display("Error: y = %h, expected %h", y, yExpected);
        $stop();
    end
endmodule