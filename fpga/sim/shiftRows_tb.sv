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
    logic pass = 1'b1; // indicates if test passed

    // Device under test
    shiftRows dut(a, y);

    initial begin
        a = 128'h3243F6A8885A308D313198A2E0370734;
        yExpected = 128'h325A9834883107A83137F68DE04330A2;
        #5;
        pass &= (y == yExpected);

        a = 128'h00010203101112132021222330313233;
        yExpected = 128'h00112233102132032031021330011223;
        #5;
        pass &= (y == yExpected);

        a = 128'h00112233445566778899AABBCCDDEEFF;
        yExpected = 128'h0055AAFF4499EE3388DD2277CC1166BB;
        #5;
        pass &= (y == yExpected);

        a = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        yExpected = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #5;
        pass &= (y == yExpected);

        a = 128'h00000000000000000000000000000000;
        yExpected = 128'h00000000000000000000000000000000;
        #5;
        pass &= (y == yExpected);

        a = 128'h1A2B3C4D5E6F708192A3B4C5D6E7F809;
        yExpected = 128'h1A6FB4095EA3F84D92E73C81D62B70C5;
        #5;
        pass &= (y == yExpected);

        if (pass)
            $display("All tests passed");
        else
            $display("Error: one or more tests failed");

        $stop();
    end
endmodule
