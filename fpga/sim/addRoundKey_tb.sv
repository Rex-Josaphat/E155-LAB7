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
    logic pass = 1'b1; // indicates if test passed

    // Device Under Test
    addRoundKey dut(a, k, y);

    initial begin
        a = 128'h3243F6A8885A308D313198A2E0370734;
        k = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        yExpected = 128'h193DE3BEA0F4E22B9AC68D2AE9F84808;
        #5; pass &= (y == yExpected);

        a = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        k = 128'h00000000000000000000000000000000;
        yExpected = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #5; pass &= (y == yExpected);

        a = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        k = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        yExpected = 128'h00000000000000000000000000000000;
        #5; pass &= (y == yExpected);

        a = 128'h00000000000000000000000000000000;
        k = 128'h123456789ABCDEF0123456789ABCDEF0;
        yExpected = 128'h123456789ABCDEF0123456789ABCDEF0;
        #5; pass &= (y == yExpected);

        a = 128'hA1B2C3D4E5F60718293A4B5C6D7E8F90;
        k = 128'h00112233445566778899AABBCCDDEEFF;
        yExpected = 128'hA1A3E1E7A1A3616FA1A3E1E7A1A3616F;
        #5; pass &= (y == yExpected);

        a = 128'h1A2B3C4D5E6F708192A3B4C5D6E7F809;
        k = 128'h0F0E0D0C0B0A09080706050403020100;
        yExpected = 128'h152531415565798995A5B1C1D5E5F909;
        #5; pass &= (y == yExpected);

        if (pass)
            $display("All tests passed");
        else
            $display("Error: one or more tests failed");

        $stop();
    end
endmodule
