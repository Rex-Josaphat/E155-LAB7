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
    logic pass = 1'b1; // indicates if test passed

    // device under test
    getNextKey dut(clk, currKey, rcon, nextKey);

    // generate clock and load signals
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // Rcon table (rounds 1..10)
    localparam logic [31:0] RCON [1:10] = '{
        32'h01000000,
        32'h02000000, 
        32'h04000000, 
        32'h08000000, 
        32'h10000000,
        32'h20000000, 
        32'h40000000, 
        32'h80000000, 
        32'h1B000000, 
        32'h36000000};

    // Expected key expansion 
    localparam logic [127:0] EXP [1:10] = '{
        128'hA0FAFE1788542CB123A339392A6C7605,
        128'hF2C295F27A96B9435935807A7359F67F,
        128'h3D80477D4716FE3E1E237E446D7A883B,
        128'hEF44A541A8525B7FB671253BDB0BAD00,
        128'hD4D1C6F87C839D87CAF2B8BC11F915BC,
        128'h6D88A37A110B3EFDDBF98641CA0093FD,
        128'h4E54F70E5F5FC9F384A64FB24EA6DC4F,
        128'hEAD27321B58DBAD2312BF5607F8D292F,
        128'hAC7766F319FADC2128D12941575C006E,
        128'hD014F9A8C9EE2589E13F0CC8B6630CA6};

    initial begin
        currKey <= 128'h2B7E151628AED2A6ABF7158809CF4F3C; // initial key

        for (int round = 1; round <= 10; round++) begin
            rcon <= RCON[round];
            nextKeyExpected <= EXP[round];
            @(posedge clk); #1; // S-box cycle delay

            if (nextKey != nextKeyExpected) begin
                $display("Error: Round %0d failed; nextKey = %h, expected %h", round, nextKey, nextKeyExpected);
                pass = 0;
            end else begin
                $display("Round %0d: Passed", round);
            end

            currKey <= nextKey; // advance to next round
        end

        if (pass) 
            $display("All rounds passed. Testbench ran successfully");
        else
            $display("Key expansion errors present");
        $stop();
    end
endmodule