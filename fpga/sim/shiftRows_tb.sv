// Josaphat Ngoga
// jngoga@g.hmc.edu
// 10/15/2025

`timescale 10ns/1ns

/////////////////////////////////////////////
// testbench_shiftRows_tb
// Tests shiftRows module for proper shifting operations.
/////////////////////////////////////////////

module shiftRows_tb();
    logic [127:0] a, y, yExpected;
    
    // device under test
    shiftRows dut(a, y);

    initial begin
        a <= 128'h3243F6A8885A308D313198A2E0370734;

        yExpected <= 128'h325A9834883107A83137F68DE04330A2; #5;

        if (y == yExpected) 
            $display("Testbench ran successfully");
        else
            $display("Error: y = %h, expected %h", y, yExpected);
        $stop();
    end
endmodule