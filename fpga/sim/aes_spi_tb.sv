`timescale 10ns/1ns
// Josaphat Ngoga
// jngoga@g.hmc.edu
// 11/1/2025
// Modified from original testbench by Josh Brake
// to test timing of AES module with SPI interface by running two transactions back to back

/////////////////////////////////////////////
// testbench_aes_spi
// Tests AES with cases from FIPS-197 appendix
// Simulates full system with SPI load
/////////////////////////////////////////////

module testbench_aes_spi();
    logic clk, load, done, sck, sdi, sdo;
    logic [127:0] key, plaintext, cyphertext, expected;
    logic [255:0] comb;
    logic [8:0] i;
    logic delay;
    logic pass = 1;


    // device under test
    aes dut(clk, sck, sdi, sdo, load, done);

    // Create dumpfile
    initial begin
      $dumpfile("testbench_aes_spi.vcd");
      $dumpvars(0, testbench_aes_spi);
    end

    // generate clock
    always begin
      clk = 1'b0; #5;
      clk = 1'b1; #5;
    end

    // ---------- TEST SEQUENCE ----------
    initial begin
      // Test case from FIPS-197 Appendix A.1, B
      key       = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
      plaintext = 128'h3243F6A8885A308D313198A2E0370734;
      expected  = 128'h3925841D02DC09FBDC118597196A0B32;

      i = 0; load = 1; delay = 1;
      comb = {plaintext, key};
      run_spi_transfer();

      if (cyphertext == expected)
        $display("Test 1 passed");
      else begin
        $display("Error in Test 1: cyphertext = %h, expected %h", cyphertext, expected);
        pass = 0;
      end

      // small gap before next test
      #100;

      // Alternate test case from Appendix C.1
      key       = 128'h000102030405060708090A0B0C0D0E0F;
      plaintext = 128'h00112233445566778899AABBCCDDEEFF;
      expected  = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;

      i = 0; load = 1; delay = 1;
      comb = {plaintext, key};
      run_spi_transfer();

      if (cyphertext == expected)
        $display("Test 2 passed");
      else begin
        $display("Error in Test 2: cyphertext = %h, expected %h", cyphertext, expected);
        pass = 0;
      end

      if (pass)
        $display("All tests passed");
      else
        $display("Error: one or more tests failed");

      $stop();
    end

    always @(posedge clk) begin
      if (i == 256) load = 1'b0;
      if (i < 256) begin
        #1; sdi = comb[255 - i];
        #1; sck = 1; #5; sck = 0;
        i = i + 1;
      end else if (done && delay) begin
        #100; delay = 0; // allow ciphertext to stabilize
      end else if (done && i < 384) begin
        #1; sck = 1; 
        #1; cyphertext[383 - i] = sdo;
        #4; sck = 0;
        i = i + 1;
      end
    end

    // dummy task to wait for SPI transfer to complete
    task run_spi_transfer;
      begin
        wait(i == 384);
      end
    endtask
endmodule
