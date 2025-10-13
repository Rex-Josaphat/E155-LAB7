// Josaphat Ngoga
// jngoga@g.hmc.edu
// 10/13/2025

/////////////////////////////////////////////
// aes
//   Top level module with SPI interface and SPI core
/////////////////////////////////////////////

module aes(input  logic clk,
           input  logic sck, 
           input  logic sdi,
           output logic sdo,
           input  logic load,
           output logic done);
                    
    logic [127:0] key, plaintext, cyphertext;
            
    aes_spi spi(sck, sdi, sdo, done, key, plaintext, cyphertext);   
    aes_core core(clk, load, key, plaintext, done, cyphertext);
endmodule

/////////////////////////////////////////////
// aes_spi
//   SPI interface.  Shifts in key and plaintext
//   Captures ciphertext when done, then shifts it out
//   Tricky cases to properly change sdo on negedge clk
/////////////////////////////////////////////

module aes_spi(input  logic sck, 
               input  logic sdi,
               output logic sdo,
               input  logic done,
               output logic [127:0] key, plaintext,
               input  logic [127:0] cyphertext);

    logic         sdodelayed, wasdone;
    logic [127:0] cyphertextcaptured;
               
    // assert load
    // apply 256 sclks to shift in key and plaintext, starting with plaintext[127]
    // then deassert load, wait until done
    // then apply 128 sclks to shift out cyphertext, starting with cyphertext[127]
    // SPI mode is equivalent to cpol = 0, cpha = 0 since data is sampled on first edge and the first
    // edge is a rising edge (clock going from low in the idle state to high).
    always_ff @(posedge sck)
        if (!wasdone)  {cyphertextcaptured, plaintext, key} = {cyphertext, plaintext[126:0], key, sdi};
        else           {cyphertextcaptured, plaintext, key} = {cyphertextcaptured[126:0], plaintext, key, sdi}; 
    
    // sdo should change on the negative edge of sck
    always_ff @(negedge sck) begin
        wasdone = done;
        sdodelayed = cyphertextcaptured[126];
    end
    
    // when done is first asserted, shift out msb before clock edge
    assign sdo = (done & !wasdone) ? cyphertext[127] : sdodelayed;
endmodule

/////////////////////////////////////////////
// aes_core
//   top level AES encryption module
//   when load is asserted, takes the current key and plaintext
//   generates cyphertext and asserts done when complete 11 cycles later
// 
//   See FIPS-197 with Nk = 4, Nb = 4, Nr = 10
//
//   The key and message are 128-bit values packed into an array of 16 bytes as
//   shown below
//        [127:120] [95:88] [63:56] [31:24]     S0,0    S0,1    S0,2    S0,3
//        [119:112] [87:80] [55:48] [23:16]     S1,0    S1,1    S1,2    S1,3
//        [111:104] [79:72] [47:40] [15:8]      S2,0    S2,1    S2,2    S2,3
//        [103:96]  [71:64] [39:32] [7:0]       S3,0    S3,1    S3,2    S3,3
//
//   Equivalently, the values are packed into four words as given
//        [127:96]  [95:64] [63:32] [31:0]      w[0]    w[1]    w[2]    w[3]
/////////////////////////////////////////////

module aes_core(input  logic         clk, 
                input  logic         load,
                input  logic [127:0] key, 
                input  logic [127:0] plaintext, 
                output logic         done, 
                output logic [127:0] cyphertext);

    // Internal signals
    logic [3:0][31:0] w, currKey, nextKey;
    logic [31:0] rcon;
    logic [3:0] roundCount, cycleCount;
    logic [127:0] state; // Holds intermediate state of the data
    logic [127:0] bfrSub, afterSub, afterShift, afterMix, bfrAdd, afterAdd;

    // Data path signals and setup
    subBytes sub(clk, bfrSub, afterSub);
    shiftRows shift(afterSub, afterShift);
    mixcolumns mix(afterShift, afterMix);
    addRoundKey add(bfrAdd, w, afterAdd);

    getNextKey keyExp(clk, currKey, rcon, nextKey);

    always_ff @(posedge clk) begin
      if (load) begin
        roundCount <= 0;
        cycleCount <= 0;
        done <= 0;

        w <= {key[127:96], key[95:64], key[63:32], key[31:0]};
        currKey <= {key[127:96], key[95:64], key[63:32], key[31:0]};

        bfrAdd <= plaintext;

      end else if (!done) begin
        // If begining, load key and plaintext
        if (roundCount == 0) begin
          if (cycleCount == 3) begin
            state <= afterAdd;
          end
        end

        // Process rounds
        if ((roundCount > 0) && (roundCount < 10)) begin
          if (cycleCount == 0) begin
            w <= nextKey;
            currKey <= nextKey;
          end if (cycleCount == 1) begin
            bfrSub <= state;
          end if (cycleCount == 2) begin
            bfrAdd <= afterMix;
          end if (cycleCount == 3) begin
            state <= afterAdd; // Next state
          end
        end 

        // If it's round 10, we're done. Skip column mixing.
        if (roundCount == 10) begin
          if (cycleCount == 0) begin
            w <= nextKey;
            currKey <= nextKey;
          end if (cycleCount == 1) begin
            bfrSub <= state;
          end if (cycleCount == 2) begin
            bfrAdd <= afterShift; // Skip mixcolumns
          end if (cycleCount == 3) begin
            cyphertext <= afterAdd;
            done <= 1;
          end
        end

        // Update cycle and round counters
        if (cycleCount == 3) begin
          cycleCount <= 0;
          if (roundCount < 10) roundCount <= roundCount + 1;
        end else begin
          cycleCount <= cycleCount + 1;
        end
      end
    end

    // rcon lookup values for rounds 1-10    
    always_comb begin
      case(roundCount)
        4'd0 : rcon = 32'h01000000;
        4'd1 : rcon = 32'h02000000;
        4'd2 : rcon = 32'h04000000;
        4'd3 : rcon = 32'h08000000;
        4'd4 : rcon = 32'h10000000;
        4'd5 : rcon = 32'h20000000;
        4'd6 : rcon = 32'h40000000;
        4'd7 : rcon = 32'h80000000;
        4'd8 : rcon = 32'h1b000000;
        4'd9 : rcon = 32'h36000000;

        default: rcon = 32'h00000000; 
      endcase
    end
endmodule

/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Combinational version which is mapped to LUTs (logic cells)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////

module sbox(input  logic [7:0] a,
            output logic [7:0] y);
            
    // sbox implemented as a ROM
    // This module is combinational and will be inferred using LUTs (logic cells)
    logic [7:0] sbox[0:255];

    initial   $readmemh("sbox.txt", sbox);
    assign y = sbox[a];
endmodule

/////////////////////////////////////////////
// sbox
//   Infamous AES byte substitutions with magic numbers
//   Synchronous version which is mapped to embedded block RAMs (EBR)
//   Section 5.1.1, Figure 7
/////////////////////////////////////////////
module sbox_sync(input		logic [7:0] a,
                 input	 	logic clk,
                 output 	logic [7:0] y);
            
    // sbox implemented as a ROM
    // This module is synchronous and will be inferred using BRAMs (Block RAMs)
    logic [7:0] sbox [0:255];

    initial   $readmemh("sbox.txt", sbox);
    
    	// Synchronous version
    	always_ff @(posedge clk) begin
    		y <= sbox[a];
    	end
endmodule

/////////////////////////////////////////////
// mixcolumns
//   Even funkier action on columns
//   Section 5.1.3, Figure 9
//   Same operation performed on each of four columns
/////////////////////////////////////////////

module mixcolumns(input  logic [127:0] a,
                  output logic [127:0] y);

    mixcolumn mc0(a[127:96], y[127:96]);
    mixcolumn mc1(a[95:64],  y[95:64]);
    mixcolumn mc2(a[63:32],  y[63:32]);
    mixcolumn mc3(a[31:0],   y[31:0]);
endmodule

/////////////////////////////////////////////
// mixcolumn
//   Perform Galois field operations on bytes in a column
//   See EQ(4) from E. Ahmed et al, Lightweight Mix Columns Implementation for AES, AIC09
//   for this hardware implementation
/////////////////////////////////////////////

module mixcolumn(input  logic [31:0] a,
                 output logic [31:0] y);
                      
        logic [7:0] a0, a1, a2, a3, y0, y1, y2, y3, t0, t1, t2, t3, tmp;
        
        assign {a0, a1, a2, a3} = a;
        assign tmp = a0 ^ a1 ^ a2 ^ a3;
    
        galoismult gm0(a0^a1, t0);
        galoismult gm1(a1^a2, t1);
        galoismult gm2(a2^a3, t2);
        galoismult gm3(a3^a0, t3);
        
        assign y0 = a0 ^ tmp ^ t0;
        assign y1 = a1 ^ tmp ^ t1;
        assign y2 = a2 ^ tmp ^ t2;
        assign y3 = a3 ^ tmp ^ t3;
        assign y = {y0, y1, y2, y3};    
endmodule

/////////////////////////////////////////////
// galoismult
//   Multiply by x in GF(2^8) is a left shift
//   followed by an XOR if the result overflows
//   Uses irreducible polynomial x^8+x^4+x^3+x+1 = 00011011
/////////////////////////////////////////////

module galoismult(input  logic [7:0] a,
                  output logic [7:0] y);

    logic [7:0] ashift;
    
    assign ashift = {a[6:0], 1'b0};
    assign y = a[7] ? (ashift ^ 8'b00011011) : ashift;
endmodule



///////////////////////////////////////////// Added Code /////////////////////////////////////////////



//////////////////////////////////
// subBytes
//  subBytes from lookup table
//  Section 5.1.1, Figure 7
//////////////////////////////////

module subBytes(input logic clk,
                input  logic [127:0] a,
                output logic [127:0] y);
                    
    sbox_sync sb0(a[127:120], clk, y[127:120]);
    sbox_sync sb1(a[119:112], clk, y[119:112]);
    sbox_sync sb2(a[111:104], clk, y[111:104]);
    sbox_sync sb3(a[103:96] , clk, y[103:96]);
    sbox_sync sb4(a[95:88]  , clk, y[95:88]);
    sbox_sync sb5(a[87:80]  , clk, y[87:80]);
    sbox_sync sb6(a[79:72]  , clk, y[79:72]);
    sbox_sync sb7(a[71:64]  , clk, y[71:64]);
    sbox_sync sb8(a[63:56]  , clk, y[63:56]);
    sbox_sync sb9(a[55:48]  , clk, y[55:48]);
    sbox_sync sb10(a[47:40] , clk, y[47:40]);
    sbox_sync sb11(a[39:32] , clk, y[39:32]);
    sbox_sync sb12(a[31:24] , clk, y[31:24]);
    sbox_sync sb13(a[23:16] , clk, y[23:16]);
    sbox_sync sb14(a[15:8]  , clk, y[15:8]);
    sbox_sync sb15(a[7:0]   , clk, y[7:0]);

endmodule

/////////////////////////////////////////////
// shiftRows
//   shift rows portion of AES algorithm
//   Section 5.1.2, Figure 8
/////////////////////////////////////////////

module shiftRows(input  logic [127:0] a,
                 output logic [127:0] y);
                 
    // row 0 (a0,a4,a8,a12) not shifted
    assign y[127:120] = a[127:120];
    assign y[95:88]   = a[95:88];
    assign y[63:56]   = a[63:56];
    assign y[31:24]   = a[31:24];
    
    // row 1 (a1,a5,a9,a13) shifted left by 1
    assign y[119:112] = a[87:80];
    assign y[87:80]   = a[55:48];
    assign y[55:48]   = a[23:16];
    assign y[23:16]   = a[119:112];
    
    // row 2 (a2,a6,a10,a14) shifted left by 2
    assign y[111:104] = a[47:40];
    assign y[79:72]   = a[15:8];
    assign y[47:40]   = a[111:104];
    assign y[15:8]    = a[79:72];
    
    // row 3 (a3,a7,a11,a15) shifted left by 3
    assign y[103:96]  = a[7:0];
    assign y[71:64]   = a[103:96];
    assign y[39:32]   = a[71:64];
    assign y[7:0]     = a[39:32];
endmodule

/////////////////////////////////////////////
// addRoundKey
//   addRoundKey portion of AES algorithm
//   Section 5.1.4, Figure 10
/////////////////////////////////////////////

module addRoundKey(input  logic [127:0] a,
                   input  logic [127:0] k,
                   output logic [127:0] y);
                   
    assign y = a ^ k;
endmodule


/////////////////////////////////////////////
// getNextKey
//   Key expansion portion of AES algorithm
//   Takes previous key and rcon
//   rotates the previous key and applies sbox to each byte
//   XOR with rcon and the previous key to get the new key
//   Section 5.2, Figure 11
/////////////////////////////////////////////

module getNextKey(input  logic clk,
                  input  logic [3:0][31:0] currKey,
                  input  logic [31:0] rcon,
                  output logic [3:0][31:0] nextKey);
                    
    logic [31:0] t;
    logic [7:0]  t0, t1, t2, t3, s0, s1, s2, s3;
    
    // rotate left by 8 bits
    assign {t0, t1, t2, t3} = currKey[0];
    assign t = {t1, t2, t3, t0};
    
    // apply sbox to each byte of t
    sbox_sync sb0(t[31:24], clk, s0);
    sbox_sync sb1(t[23:16], clk, s1);
    sbox_sync sb2(t[15:8], clk, s2);
    sbox_sync sb3(t[7:0], clk, s3);
    
    // generate next words
    assign nextKey[0] = currKey[0] ^ ({s0, s1, s2, s3} ^ rcon);
    assign nextKey[1] = currKey[1] ^ nextKey[0];
    assign nextKey[2] = currKey[2] ^ nextKey[1];
    assign nextKey[3] = currKey[3] ^ nextKey[2];

endmodule