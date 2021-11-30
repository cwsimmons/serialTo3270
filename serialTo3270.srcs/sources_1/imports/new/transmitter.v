`timescale 1ns / 1ps

/*
 * IBM 3270 Coax Transmitter (Type A)
 * 
 * Copyright 2020, Christopher Simmons
 * Date:   9/19/2020
 */

module transmitter (
    input clk,
    input reset,
    input sclk,             // 2 x 2.358 MHz
    
    input enable,

    input dataAvailable,
    input last,
    input [15:0] data,
    output reg ren,

    output serialOut,
    output serialOutComplement,
    output serialOutDelayed,
    output reg active
);
    
    parameter spacing = 0;
    
    parameter [16:0] header = 17'b11100010101010101;
    parameter [5:0] trailer = 6'b111101;
    
    reg [9:0] delayReg;
    
    reg [2:0] txState;
    reg [4:0] bitCount;
    

    reg pending;
    reg pendingAck;
    reg pendingAckPrev;
    reg [9:0] pendingWord;
    reg pendingLast;

    reg [9:0] currentWord;
    reg currentLast;
    wire [11:0] packedWord;
    wire parityBit;
    
    assign parityBit = ^{1'b1, currentWord};
    assign packedWord = {1'b1, currentWord, parityBit};
    
    assign serialOut = (txState == 0) ? 1'b0:
                       (txState == 1) ? header[bitCount] :
                       (txState == 2) ? packedWord[11 - bitCount[4:1]] ~^ bitCount[0] :
                       (txState == 3) ? trailer[bitCount] : 1'b0;

    assign serialOutComplement = (txState[1:0]) ? !serialOut : 1'b0;
                       
    assign serialOutDelayed = delayReg[9];
    
    always @(posedge clk)
    begin
        if (reset)
            delayReg <= 10'b0;
        else
            delayReg <= {delayReg[8:0], serialOut};
    end

    always @(posedge clk)
    begin

        pendingAckPrev <= pendingAck;
        ren <= 0;
        if (reset)
            pending <= 0;
        if (dataAvailable && !pending && enable)
        begin
            ren <= 1;
            pending <= 1;
            pendingWord <= data[9:0];
            pendingLast <= last;
        end
        else if (pendingAck && !pendingAckPrev)
        begin
            pending <= 0;
        end

        if (txState)
            active <= 1;
        else
            active <= 0;

    end

    
    always @(posedge sclk or posedge reset)
    begin
    
        pendingAck <= 0;

        if (reset)
        begin

            txState <= 0;
            bitCount <= 0;
            currentWord <= 0;

        end
        else if (txState == 0)
        begin
        
            if (pending)
            begin
                txState <= 1;
                bitCount <= 0;
                pendingAck <= 1;
                currentWord <= pendingWord;
                currentLast <= pendingLast;
            end
            
        end
        else if (txState == 1)
        begin
        
            if (bitCount == 16)
            begin
                bitCount <= 0;
                txState <= 2;
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
            
        end
        else if (txState == 2)
        begin
        
            if (bitCount == 23)
            begin
                bitCount <= 0;
                
                if (pending && !currentLast)
                begin
                    pendingAck <= 1;
                    currentWord <= pendingWord;
                    currentLast <= pendingLast;
                end
                else
                begin
                    txState <= 3;
                end	
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
        
        end
        else if (txState == 3)
        begin
        
            if (bitCount == 5)
            begin
                txState <= 4;
                bitCount <= 0;
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
        
        end
        else if (txState == 4)
        begin
        
            if (bitCount == spacing)
            begin
                txState <= 0;
                bitCount <= 0;
            end
            else
            begin
                bitCount <= bitCount + 1;
            end
        
        end
    end
    
endmodule
