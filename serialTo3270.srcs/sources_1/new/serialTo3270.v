`timescale 1ns / 1ps

/*
 * Serial to IBM 3270 Coax
 * 
 * Author: Chris Simmons
 * Date:   3/04/2019
 */

module serialTo3270(
    input clk,
    input reset,
    
    input uartIn,
    output uartOut,
    
    input sclk12,
    input serialIn,
    output serialOut,
    output serialOutComplement,
    output serialOutDelayed,
    output TxActive
);

    parameter CLOCKS_PER_BIT_UART = 868;
    parameter BUFFER_SIZE_EXP = 11;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
 *           CLOCK DIVIDER             *
 *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

    reg sclk;
    reg [1:0] divider;
    
    always @(posedge sclk12 or posedge reset)
    begin
       if (reset)
       begin
           sclk <= 0;
           divider <= 0;
       end
       else if (divider == 2)
       begin
           sclk <= ~sclk;
           divider <= 0;
       end
       else
           divider <= divider + 1;
    
    end

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
 *           LINE MONITOR              *
 *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

    wire RxActive;
    reg receiving;
    reg waiting;
    reg prevRxActive;
    reg prevTxActive;
    reg [9:0] RxTimeout;

    always @(posedge clk)
    begin
        prevRxActive <= RxActive;
        prevTxActive <= TxActive;
        
        if (reset)
        begin
            receiving <= 0;
            waiting <= 0;
            RxTimeout <= 0;
        end
        else if (prevTxActive && !TxActive)
        begin
            
            receiving <= 1;
            waiting <= 1;
            RxTimeout <= 0;

        end
        else if (!prevRxActive && RxActive)
        begin
            
            waiting <= 0;

        end
        else if ((prevRxActive && !RxActive) || (RxTimeout == 700))
        begin
            
            waiting <= 0;
            receiving <= 0;

        end
        else if (waiting)
        begin
            
            RxTimeout <= RxTimeout + 1;

        end

    end

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
 *       T R A N S M I T T E R         *
 *%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

    wire [7:0] TxSerialByte;
    wire TxSerialByteAvailable;
    wire [7:0] TxSlipByte;
    wire TxSlipByteAvailable;
    wire [BUFFER_SIZE_EXP-1:0] TxLength;
    wire TxLengthAvailable;

    uartReceiver #(CLOCKS_PER_BIT_UART) RxUart(
        .clk                    (clk),
        .reset                  (reset),
        .serialIn               (uartIn),
        .data                   (TxSerialByte),
        .dataAvailable          (TxSerialByteAvailable)
    );

    slipRx #(BUFFER_SIZE_EXP) RxSlip(
        .clk                    (clk),
        .reset                  (reset),
        .dataIn                 (TxSerialByte),
        .dataInAvailable        (TxSerialByteAvailable),
        .dataOut                (TxSlipByte),
        .dataOutAvailable       (TxSlipByteAvailable),
        .lengthOut              (TxLength),
        .lengthOutAvailable     (TxLengthAvailable)
    );

    reg [7:0] TxLowerByte;
    reg TxLowerByteReceived;
    reg [9:0] TxWord;
    reg TxWordAvailable;

    always @(posedge clk)
    begin
        
        TxWord <= 0;
        TxWordAvailable <= 0;

        if (reset || TxLengthAvailable)
            TxLowerByteReceived <= 0;
        else if (TxSlipByteAvailable)
        begin
            if (!TxLowerByteReceived)
            begin
                TxLowerByte <= TxSlipByte;
                TxLowerByteReceived <= 1;
            end
            else
            begin
                TxWord <= {TxSlipByte[1:0], TxLowerByte};
                TxWordAvailable <= 1;
                TxLowerByteReceived <= 0;
            end
        end
    end

    wire [9:0] TxBufferedWord;
    wire TxBufferedWordAvailable;
    wire TxBufferedWordAcknowledge;

    wire [BUFFER_SIZE_EXP-1:0] TxBufferedLength;
    wire TxBufferedLengthAvailable;
    reg TxBufferedLengthAcknowledge;


    fifo #(10,BUFFER_SIZE_EXP) TxDataFifo(
        .clk                    (clk),
        .reset                  (reset),
        .mode                   (1'b1),
        .wen                    (TxWordAvailable),
        .ren                    (TxBufferedWordAcknowledge),
        .write                  (TxWord),
        .read                   (TxBufferedWord),
        .state                  (TxBufferedWordAvailable),
        .occupancy              ()
    );

    fifo #(BUFFER_SIZE_EXP,4) TxLengthFifo(
        .clk                    (clk),
        .reset                  (reset),
        .mode                   (1'b1),
        .wen                    (TxLengthAvailable),
        .ren                    (TxBufferedLengthAcknowledge),
        .write                  (TxLength/2),
        .read                   (TxBufferedLength),
        .state                  (TxBufferedLengthAvailable),
        .occupancy              ()
    );


    reg TxBusy;
    reg [BUFFER_SIZE_EXP-1:0] TxRemaining;
    reg prevReceiving;

    always @(posedge clk)
    begin
        TxBufferedLengthAcknowledge <= 0;
        prevReceiving <= receiving;
        if (reset)
        begin
            TxBusy <= 0;
            TxRemaining <= 0;
        end
        else if (!TxBusy && TxBufferedLengthAvailable)
        begin
            TxRemaining <= TxBufferedLength;
            TxBufferedLengthAcknowledge <= 1;
            TxBusy <= 1;
        end
        else if (TxBufferedWordAcknowledge && |TxRemaining)
        begin
            TxRemaining <= TxRemaining - 1;
        end
        else if (prevReceiving && !receiving)
        begin
            TxBusy <= 0;
        end
    end





    transmitter TxCoax(
        .clk                    (clk),
        .reset                  (reset),
        .sclk                   (sclk),
        .dataAvailable          (|TxRemaining),
        .data                   (TxBufferedWord),
        .ren                    (TxBufferedWordAcknowledge),
        .serialOut              (serialOut),
        .serialOutComplement    (serialOutComplement),
        .serialOutDelayed       (serialOutDelayed),
        .active                 (TxActive)
    );




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*
*           R E C E I V E R
*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

    wire [11:0] RxWord;
    wire RxWordAvailable;

    wire RxEnded;
    assign RxEnded = prevReceiving && !receiving;

    receiver RxCoax(
        .clk                    (clk),
        .reset                  (reset),
        .enable                 (!TxActive),
        .serialIn               (serialIn),
        .active                 (RxActive),
        .rxWord                 (RxWord),
        .wordAvailable          (RxWordAvailable)
    );

    reg RxBufferedDataAcknowledge;
    wire [12:0] RxBufferedData;
    wire RxBufferedDataAvailable;

    fifo #(13,BUFFER_SIZE_EXP) RxDataFifo(
        .clk                    (clk),
        .reset                  (reset),
        .mode                   (1'b1),
        .wen                    (RxWordAvailable || RxEnded),
        .ren                    (RxBufferedDataAcknowledge),
        .write                  ({RxEnded, RxWord}),
        .read                   (RxBufferedData),
        .state                  (RxBufferedDataAvailable),
        .occupancy              ()
    );

    reg [12:0] RxNarrowerData;
    reg RxNarrowerAvailable;
    reg RxNarrowerHighAcked;
    reg RxNarrowerLowAcked;

    wire RxNarrowerAcknowledge;

    always @(posedge clk)
    begin
        RxBufferedDataAcknowledge <= 0;
        if (reset)
        begin
            RxNarrowerAvailable <= 0;
            RxNarrowerHighAcked <= 0;
            RxNarrowerLowAcked <= 0;
        end
        else if (!RxNarrowerAvailable)
        begin
            if (RxBufferedDataAvailable)
            begin
                RxNarrowerData <= RxBufferedData;
                RxNarrowerAvailable <= 1;
                RxBufferedDataAcknowledge <= 1;
            end
        end
        else if (RxNarrowerAcknowledge)
        begin
            if (!RxNarrowerLowAcked)
            begin
                if (!RxNarrowerData[12])
                    RxNarrowerLowAcked <= 1;
                else
                    RxNarrowerAvailable <= 0;
            end
            else
            begin
                RxNarrowerAvailable <= 0;
                RxNarrowerLowAcked <= 0;
            end
        end
    end



    wire RxSlipDataOutAcknowledge;
    wire [7:0] RxSlipDataOut;
    wire RxSlipDataOutAvailable;

    slipTx TxSlip(
        .clk                    (clk),
        .reset                  (reset),
        .dataOutAcknowledge     (RxSlipDataOutAcknowledge),
        .dataIn                 (RxNarrowerLowAcked ? {4'b0000, RxNarrowerData[11:8]} : RxNarrowerData[7:0]),
        .dataInAvailable        (RxNarrowerAvailable),
        .dataInAck              (RxNarrowerAcknowledge),
        .endIn                  (RxNarrowerData[12]),
        .dataOut                (RxSlipDataOut),
        .dataOutAvailable       (RxSlipDataOutAvailable)
    );

    uartTransmitter #(CLOCKS_PER_BIT_UART) TxUart(
        .clk                    (clk),
        .reset                  (reset),
        .dataAvailable          (RxSlipDataOutAvailable),
        .data                   (RxSlipDataOut),
        .ren                    (RxSlipDataOutAcknowledge),
        .serialOut              (uartOut)
    );

endmodule
