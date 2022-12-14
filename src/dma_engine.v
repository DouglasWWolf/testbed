`timescale 1ns / 1ps
//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 21-Jul-22  DWW  1000  Initial creation
//====================================================================================

/*

    This module serves as a proxy for AXI read-write transactions.

    On the AXI4-lite slave interface, there are three 32-bit registers:
       Offset 0x00 = Data 
       Offset 0x04 = High 32-bits of AXI address to read/write from/to
       Offset 0x08 = Low  32-bits of AXI address to read/write from/to

    Use in an application is simple:
        Use the address registers to define the AXI address you are interested in, 
        then either perform an AXI-read of the data register, or an AXI-write to the
        data-register.   The read/write transaction will occur at at specified
        address.

*/


//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
//            Application-specific logic goes at the bottom of the file
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

module dma_engine#
(
    parameter integer AXI_SRC_ADDR_OFFSET = 0,
    parameter integer AXI_DST_ADDR_OFFSET = 64'hC200_0000,
    parameter integer AXI_DATA_WIDTH      = 512,
    parameter integer AXI_ADDR_WIDTH      =  64,
    parameter integer S_AXI_ADDR_WIDTH    =   5,
    parameter integer S_AXI_DATA_WIDTH    =  32 

)
(
    input wire  AXI_ACLK,
    input wire  AXI_ARESETN,

    output wire FIFO_WRITE, FIFO_READ, FIFO_FULL, FIFO_EMPTY,
    output wire WR_ACK, WR_RST_BUSY,
    output wire[1:0] BLOCKS_IN_FIFO, M01_WRITE_STATE,

    //==========================================================================
    //            This defines the AXI4-Lite slave control interface
    //==========================================================================
    // "Specify write address"              -- Master --    -- Slave --
    input  wire [S_AXI_ADDR_WIDTH-1 : 0]    S_AXI_AWADDR,   
    input  wire                             S_AXI_AWVALID,  
    output wire                                             S_AXI_AWREADY,
    input  wire  [2 : 0]                    S_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    input  wire [S_AXI_DATA_WIDTH-1 : 0]    S_AXI_WDATA,      
    input  wire                             S_AXI_WVALID,
    input  wire [(S_AXI_DATA_WIDTH/8)-1:0]  S_AXI_WSTRB,
    output wire                                             S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output  wire [1 : 0]                                    S_AXI_BRESP,
    output  wire                                            S_AXI_BVALID,
    input   wire                            S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input  wire [S_AXI_ADDR_WIDTH-1 : 0]    S_AXI_ARADDR,     
    input  wire                             S_AXI_ARVALID,
    input  wire [2 : 0]                     S_AXI_ARPROT,     
    output wire                                             S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output  wire [S_AXI_DATA_WIDTH-1 : 0]                   S_AXI_RDATA,
    output  wire                                            S_AXI_RVALID,
    output  wire [1 : 0]                                    S_AXI_RRESP,
    input   wire                            S_AXI_RREADY,
    //==========================================================================



   

    //==========================================================================
    //  This defines the AXI Master interface that connects to the data source
    //==========================================================================
    // "Specify write address"             -- Master --      -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]     M00_AXI_AWADDR,   
    output wire                            M00_AXI_AWVALID,  
    input  wire                                              M00_AXI_AWREADY,
    output wire  [2 : 0]                   M00_AXI_AWPROT,

    // "Write Data"                        -- Master --      -- Slave --
    output wire [AXI_DATA_WIDTH-1 : 0]     M00_AXI_WDATA,      
    output wire                            M00_AXI_WVALID,
    output wire [(AXI_DATA_WIDTH/8)-1:0]   M00_AXI_WSTRB,
    input  wire                                              M00_AXI_WREADY,

    // "Send Write Response"               -- Master --      -- Slave --
    input  wire [1 : 0]                                      M00_AXI_BRESP,
    input  wire                                              M00_AXI_BVALID,
    output wire                            M00_AXI_BREADY,

    // "Specify read address"              -- Master --      -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]     M00_AXI_ARADDR,     
    output wire                            M00_AXI_ARVALID,
    output wire [2 : 0]                    M00_AXI_ARPROT,     
    input  wire                                              M00_AXI_ARREADY,

    // "Read data back to master"          -- Master --      -- Slave --
    input  wire [AXI_DATA_WIDTH-1 : 0]                       M00_AXI_RDATA,
    input  wire                                              M00_AXI_RVALID,
    input  wire [1 : 0]                                      M00_AXI_RRESP,
    output wire                            M00_AXI_RREADY,


    // Full AXI4 signals driven by master
    output wire[3:0]                       M00_AXI_AWID,
    output wire[7:0]                       M00_AXI_AWLEN,
    output wire[2:0]                       M00_AXI_AWSIZE,
    output wire[1:0]                       M00_AXI_AWBURST,
    output wire                            M00_AXI_AWLOCK,
    output wire[3:0]                       M00_AXI_AWCACHE,
    output wire[3:0]                       M00_AXI_AWQOS,
    output wire                            M00_AXI_WLAST,
    output wire                            M00_AXI_ARLOCK,
    output wire[3:0]                       M00_AXI_ARID,
    output wire[7:0]                       M00_AXI_ARLEN,
    output wire[2:0]                       M00_AXI_ARSIZE,
    output wire[1:0]                       M00_AXI_ARBURST,
    output wire[3:0]                       M00_AXI_ARCACHE,
    output wire[3:0]                       M00_AXI_ARQOS,

    // Full AXI4 signals driven by slave
    input  wire                                              M00_AXI_RLAST,
    //==========================================================================
    
     
    
    //==========================================================================
    //  This defines the AXI Master interface that connects to the destination
    //==========================================================================
    // "Specify write address"             -- Master --      -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]     M01_AXI_AWADDR,   
    output wire                            M01_AXI_AWVALID,  
    input  wire                                              M01_AXI_AWREADY,
    output wire  [2 : 0]                   M01_AXI_AWPROT,

    // "Write Data"                        -- Master --      -- Slave --
    output wire [AXI_DATA_WIDTH-1 : 0]     M01_AXI_WDATA,      
    output wire                            M01_AXI_WVALID,
    output wire [(AXI_DATA_WIDTH/8)-1:0]   M01_AXI_WSTRB,
    input  wire                                              M01_AXI_WREADY,

    // "Send Write Response"               -- Master --      -- Slave --
    input  wire [1 : 0]                                      M01_AXI_BRESP,
    input  wire                                              M01_AXI_BVALID,
    output wire                            M01_AXI_BREADY,

    // "Specify read address"              -- Master --      -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]     M01_AXI_ARADDR,     
    output wire                            M01_AXI_ARVALID,
    output wire [2 : 0]                    M01_AXI_ARPROT,     
    input  wire                                              M01_AXI_ARREADY,

    // "Read data back to master"          -- Master --      -- Slave --
    input  wire [AXI_DATA_WIDTH-1 : 0]                       M01_AXI_RDATA,
    input  wire                                              M01_AXI_RVALID,
    input  wire [1 : 0]                                      M01_AXI_RRESP,
    output wire                            M01_AXI_RREADY,


    // Full AXI4 signals driven by master
    output wire[3:0]                       M01_AXI_AWID,
    output wire[7:0]                       M01_AXI_AWLEN,
    output wire[2:0]                       M01_AXI_AWSIZE,
    output wire[1:0]                       M01_AXI_AWBURST,
    output wire                            M01_AXI_AWLOCK,
    output wire[3:0]                       M01_AXI_AWCACHE,
    output wire[3:0]                       M01_AXI_AWQOS,
    output wire                            M01_AXI_WLAST,
    output wire                            M01_AXI_ARLOCK,
    output wire[3:0]                       M01_AXI_ARID,
    output wire[7:0]                       M01_AXI_ARLEN,
    output wire[2:0]                       M01_AXI_ARSIZE,
    output wire[1:0]                       M01_AXI_ARBURST,
    output wire[3:0]                       M01_AXI_ARCACHE,
    output wire[3:0]                       M01_AXI_ARQOS,

    // Full AXI4 signals driven by slave
    input  wire                                              M01_AXI_RLAST
    //==========================================================================



 );




    //=========================================================================================================
    // These are parameters and variables that must be accessible to the rest of the module
    //=========================================================================================================

    // This is the number of bytes in a burst.  Since AXI bursts aren't allowed to cross
    // 4096-byte boundaries, 4096 is the maximum number of bytes in a single burst
    localparam BLOCK_SIZE      = 4096;   

    // These calculations assume AXI_DATA_WIDTH is a power of 2
    localparam BYTES_PER_BEAT  = AXI_DATA_WIDTH / 8;
    localparam BEATS_PER_BURST = BLOCK_SIZE / BYTES_PER_BEAT;
    localparam AxSIZE          = $clog2(BYTES_PER_BEAT);  
    localparam INCR_BURST      = 1;

    localparam REG_SRC_H    = 0;    // Hi word of the DMA source address
    localparam REG_SRC_L    = 1;    // Lo word of the DMA source address
    localparam REG_DST_H    = 2;    // Hi word of the DMA destination address
    localparam REG_DST_L    = 3;    // Lo word of the DMA destination address
    localparam REG_COUNT    = 4;    // Number of 4K blocks to DMA transfer
    localparam REG_CTL_STAT = 5;    // Combined control and status register

    // Storage for the above registers.  (We don't actually store CTL_STAT)    
    reg [31:0] register[0:4];

    // When this is pulsed high, the DMA state-machine springs into action.
    reg        start_dma;       
    
    // The state of the DMA state machine
    reg[1:0]   dma_state;   

    // The number of data blocks currently stored in the FIFO
    reg[1:0]   blocks_in_fifo;   

    // This is needed by the FIFO
    wire RESET = ~AXI_ARESETN;

    // This keeps track of whether the DMA engine is idle
    wire is_dma_engine_idle = (start_dma == 0 && dma_state == 0);

    // This will pulse high for 1 cycle every time a data block gets
    // written to the DMA destination
    reg  write_burst_complete;

    // We use these two registers to signal to the FIFO
    reg  fifo_write, fifo_read;

    // The FIFO uses these register to provide information back to us
    wire fifo_empty, fifo_full;         

    assign FIFO_EMPTY = fifo_empty;
    assign FIFO_WRITE = fifo_write;
    assign FIFO_READ  = fifo_read;
    assign FIFO_FULL  = fifo_full;
    //=========================================================================================================




    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //          This section is AXI4 Master (with bursting) logic that transfers to/from a FIFO
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    //=========================================================================================================
    // FSM logic used for reading from a slave device.
    //
    //  To start:   amci00_raddr = Address to read from
    //              amci00_read  = Pulsed high for one cycle
    //
    //  At end:   Read is complete when "amci00_ridle" goes high.
    //            amci00_rresp = The AXI "read response" that is used to indicate success or failure
    //=========================================================================================================

    // Define the handshakes for AXI channels we need
    wire M00_R_HANDSHAKE  = M00_AXI_RVALID  & M00_AXI_RREADY;
    wire M00_AR_HANDSHAKE = M00_AXI_ARVALID & M00_AXI_ARREADY;
    
    // Assign all of the "read transaction" signals that aren't in the AXI4-Lite spec

    reg                     m00_read_state;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0] amci00_raddr;
    reg                     amci00_read;

    // FSM user interface outputs
    reg[1:0]                amci00_rresp;
    wire                    amci00_ridle = (m00_read_state == 0 && amci00_read == 0);     

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0] m00_axi_araddr;  assign M00_AXI_ARADDR  = m00_axi_araddr;
    reg                     m00_axi_arvalid; assign M00_AXI_ARVALID = m00_axi_arvalid;
    reg                     m00_axi_rready;  assign M00_AXI_RREADY  = m00_axi_rready;
    
    // Wire up the AXI interface outputs
    assign M00_AXI_ARBURST = INCR_BURST;
    assign M00_AXI_ARSIZE  = AxSIZE;
    assign M00_AXI_ARLEN   = BEATS_PER_BURST - 1;
    assign M00_AXI_ARPROT  = 1;
    assign M00_AXI_ARLOCK  = 0;   // Normal signaling
    assign M00_AXI_ARID    = 1;   // Arbitrary ID
    assign M00_AXI_ARBURST = 1;   // Increment address on each beat of the burst (unused)
    assign M00_AXI_ARCACHE = 2;   // Normal, no cache, no buffer
    assign M00_AXI_ARQOS   = 0;   // Lowest quality of service (unused)
    //=========================================================================================================
    always @(posedge AXI_ACLK) begin

        fifo_write <= 0;

        if (AXI_ARESETN == 0) begin
            m00_read_state  <= 0;
            m00_axi_arvalid <= 0;
            m00_axi_rready  <= 0;
        end else case (m00_read_state)

            // Here we are waiting around for someone to raise "amci00_read", which signals us to begin
            // a AXI read at the address specified in "amci00_raddr"
            0:  if (amci00_read) begin
                    m00_axi_araddr  <= amci00_raddr;
                    m00_axi_arvalid <= 1;
                    m00_axi_rready  <= 1;
                    m00_read_state  <= 1;
                end else begin
                    m00_axi_arvalid <= 0;
                    m00_axi_rready  <= 0;
                    m00_read_state  <= 0;
                end
            
            // Wait around for the slave to raise M00_AXI_RVALID, which tells us that M00_AXI_RDATA
            // contains the data we requested
            1:  begin
                    if (M00_AR_HANDSHAKE) begin
                        m00_axi_arvalid <= 0;
                    end

                    // Every time we see the R(ead)-channel handshake, the data in M00_AXI_RDATA
                    // will be written to the FIFO
                    if (M00_R_HANDSHAKE) begin
                        fifo_write    <= 1;
                        if (M00_AXI_RLAST) begin
                            m00_axi_rready <= 0;
                            m00_read_state <= 0;
                            amci00_rresp   <= M00_AXI_RRESP;
                        end
                    end
                end

        endcase
    end
    //=========================================================================================================



    //=========================================================================================================
    // FSM logic used for reading from the FIFO and writing data to the DMA destination
    //
    //  To start:   
    //              
    //              
    //
    //  At end:     
    //              
    //=========================================================================================================
    reg[1:0] m01_write_state; assign M01_WRITE_STATE = m01_write_state;
    reg[7:0] beats_remaining;

    // Wire up the registered AXI outputs
    reg[AXI_ADDR_WIDTH-1:0] m01_axi_awaddr;  assign M01_AXI_AWADDR  = m01_axi_awaddr;
    reg[AXI_DATA_WIDTH-1:0] m01_axi_wdata;   assign M01_AXI_WDATA   = m01_axi_wdata;
    reg                     m01_axi_awvalid; assign M01_AXI_AWVALID = m01_axi_awvalid;
    reg                     m01_axi_wvalid;  assign M01_AXI_WVALID  = m01_axi_wvalid;
    reg                     m01_axi_bready;  assign M01_AXI_BREADY  = m01_axi_bready;
    reg                     m01_axi_wlast;   assign M01_AXI_WLAST   = m01_axi_wlast;

    // Wire up the hard-coded AXI outputs
    assign M01_AXI_AWPROT  = 0;
    assign M01_AXI_AWSIZE  = AxSIZE;
    assign M01_AXI_AWLEN   = BEATS_PER_BURST - 1;
    assign M01_AXI_AWBURST = INCR_BURST;
    assign M01_AXI_WSTRB   = (1 << BYTES_PER_BEAT) -1;

    // Define the handshakes for AXI channels we need
    wire M01_AW_HANDSHAKE = M01_AXI_AWVALID & M01_AXI_AWREADY;
    wire M01_W_HANDSHAKE  = M01_AXI_WVALID  & M01_AXI_WREADY;
    wire M01_B_HANDSHAKE  = M01_AXI_BVALID  & M01_AXI_BREADY;
    //=========================================================================================================
    reg[7:0] beat_count; 

    always @(posedge AXI_ACLK) begin
        
        // These signals should be low on any clock cycle they aren't explicitly driven high
        write_burst_complete <= 0;
        m01_axi_wvalid       <= 0;
        fifo_read            <= 0;
        
        // If we're in RESET mode...
        if (AXI_ARESETN == 0) begin
            m01_write_state <= 0;
            m01_axi_awvalid <= 0;
            m01_axi_wvalid  <= 0;
            m01_axi_bready  <= 0; 
        end        
        
        // Otherwise, we're not in RESET and our state machine is running
        else case (m01_write_state)
            
            // Wait for the signal to start, then record the AXI address where
            // we should start writing data
            0:  if (start_dma) begin
                    m01_axi_awaddr   <= {register[REG_DST_H], register[REG_DST_L]} + AXI_DST_ADDR_OFFSET;
                    m01_write_state  <= 1;
                end

            // If there is a block waiting for us in the FIFO... 
            1:  if (blocks_in_fifo) begin
                    m01_axi_bready  <= 0;                    // We'll assert this after the burst
                    m01_axi_awvalid <= 1;                    // Tell the slave that the address on the bus is valid
                    beats_remaining <= BEATS_PER_BURST;      // This is how many beats we have yet to write to the bus
                    if (M01_AW_HANDSHAKE) begin              // If we see the "Write-Address" handshake...
                        m01_axi_awvalid <= 0;                //   Stop saying the address is valid
                        m01_write_state <= 2;                //   Go start writing data beats to the AXI bus
                    end
                end else begin
                    if (is_dma_engine_idle) m01_write_state <= 0;
                end
            
            
            // If there is data available in the FIFO, send it to the AXI destination
            2:  if (fifo_empty == 0) begin
                    m01_axi_wvalid  <= 1;
                    m01_axi_wlast   <= (beats_remaining == 1);
                    if (M01_W_HANDSHAKE) begin
                        fifo_read <= 1;
                        if (beats_remaining == 1) begin
                            m01_axi_bready  <= 1;
                            m01_write_state <= 3;
                        end
                        beats_remaining <= beats_remaining - 1;
                    end
                end

            3:  if (M01_B_HANDSHAKE) begin
                    m01_axi_bready       <= 0;
                    m01_axi_awaddr       <= m01_axi_awaddr + BLOCK_SIZE;
                    m01_write_state      <= 1;
                    write_burst_complete <= 1;
                end

        endcase
    end
    //=========================================================================================================





    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                           This section is standard AXI4-Lite Slave logic
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    // These are valid values for BRESP and RRESP
    localparam OKAY   = 0;
    localparam SLVERR = 2;

    // These are for communicating with application-specific read and write logic
    reg  user_read_start,  user_read_idle;
    reg  user_write_start, user_write_idle;
    wire user_write_complete = (user_write_start == 0) & user_write_idle;
    wire user_read_complete  = (user_read_start  == 0) & user_read_idle;


    // Define the handshakes for all 5 slave AXI channels
    wire S_B_HANDSHAKE  = S_AXI_BVALID  & S_AXI_BREADY;
    wire S_R_HANDSHAKE  = S_AXI_RVALID  & S_AXI_RREADY;
    wire S_W_HANDSHAKE  = S_AXI_WVALID  & S_AXI_WREADY;
    wire S_AR_HANDSHAKE = S_AXI_ARVALID & S_AXI_ARREADY;
    wire S_AW_HANDSHAKE = S_AXI_AWVALID & S_AXI_AWREADY;

        
    //=========================================================================================================
    // FSM logic for handling AXI4-Lite read-from-slave transactions
    //=========================================================================================================
    // When a valid address is presented on the bus, this register holds it
    reg[S_AXI_ADDR_WIDTH-1:0] s_axi_araddr;

    // Wire up the AXI interface outputs
    reg                       s_axi_arready; assign S_AXI_ARREADY = s_axi_arready;
    reg                       s_axi_rvalid;  assign S_AXI_RVALID  = s_axi_rvalid;
    reg[1:0]                  s_axi_rresp;   assign S_AXI_RRESP   = s_axi_rresp;
    reg[S_AXI_DATA_WIDTH-1:0] s_axi_rdata;   assign S_AXI_RDATA   = s_axi_rdata;
     //=========================================================================================================
    reg s_read_state;
    always @(posedge AXI_ACLK) begin
        user_read_start <= 0;
        
        if (AXI_ARESETN == 0) begin
            s_read_state  <= 0;
            s_axi_arready <= 1;
            s_axi_rvalid  <= 0;
        end else case(s_read_state)

        0:  begin
                s_axi_rvalid <= 0;                      // RVALID will go high only when we have filled in RDATA
                if (S_AXI_ARVALID) begin                // If the AXI master has given us an address to read...
                    s_axi_arready   <= 0;               //   We are no longer ready to accept an address
                    s_axi_araddr    <= S_AXI_ARADDR;    //   Register the address that is being read from
                    user_read_start <= 1;               //   Start the application-specific read-logic
                    s_read_state    <= 1;               //   And go wait for that read-logic to finish
                end
            end

        1:  if (user_read_complete) begin               // If the application-specific read-logic is done...
                s_axi_rvalid <= 1;                      //   Tell the AXI master that RDATA and RRESP are valid
                if (S_R_HANDSHAKE) begin                //   Wait for the AXI master to say "OK, I saw your response"
                    s_axi_rvalid  <= 0;                 //     The AXI master has registered our data
                    s_axi_arready <= 1;                 //     Once that happens, we're ready to start a new transaction
                    s_read_state  <= 0;                 //     And go wait for a new transaction to arrive
                end
            end

        endcase
    end
    //=========================================================================================================


    //=========================================================================================================
    // FSM logic for handling AXI4-Lite write-to-slave transactions
    //=========================================================================================================

    // When a valid address is presented on the bus, this register holds it
    reg[S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;

    // When valid write-data is presented on the bus, this register holds it
    reg[S_AXI_DATA_WIDTH-1:0] s_axi_wdata;
    
    // Wire up the AXI interface outputs
    reg      s_axi_awready; assign S_AXI_AWREADY = s_axi_arready;
    reg      s_axi_wready;  assign S_AXI_WREADY  = s_axi_wready;
    reg      s_axi_bvalid;  assign S_AXI_BVALID  = s_axi_bvalid;
    reg[1:0] s_axi_bresp;   assign S_AXI_BRESP   = s_axi_bresp;
    //=========================================================================================================
    reg s_write_state;
    always @(posedge AXI_ACLK) begin
        user_write_start <= 0;
        if (AXI_ARESETN == 0) begin
            s_write_state <= 0;
            s_axi_awready <= 1;
            s_axi_wready  <= 1;
            s_axi_bvalid  <= 0;
        end else case(s_write_state)

        0:  begin
                s_axi_bvalid <= 0;                    // BVALID will go high only when we have filled in BRESP

                if (S_AW_HANDSHAKE) begin             // If this is the write-address handshake...
                    s_axi_awready <= 0;               //     We are no longer ready to accept a new address
                    s_axi_awaddr  <= S_AXI_AWADDR;    //     Keep track of the address we should write to
                end

                if (S_W_HANDSHAKE) begin              // If this is the write-data handshake...
                    s_axi_wready     <= 0;            //     We are no longer ready to accept new data
                    s_axi_wdata      <= S_AXI_WDATA;  //     Keep track of the data we're supposed to write
                    user_write_start <= 1;            //     Start the application-specific write logic
                    s_write_state    <= 1;            //     And go wait for that write-logic to complete
                end
            end

        1:  if (user_write_complete) begin            // If the application-specific write-logic is done...
                s_axi_bvalid <= 1;                    //   Tell the AXI master that BRESP is valid
                if (S_B_HANDSHAKE) begin              //   Wait for the AXI master to say "OK, I saw your response"
                    s_axi_awready <= 1;               //     Once that happens, we're ready for a new address
                    s_axi_wready  <= 1;               //     And we're ready for new data
                    s_write_state <= 0;               //     Go wait for a new transaction to arrive
                end
            end

        endcase
    end
    //=========================================================================================================




    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                    The state machines in this section are the DMA engine
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><



    //=========================================================================================================
    // This state machine implements the "read" side of the DMA engine, reading blocks of data from the
    // source and placing them into the FIFO.
    //=========================================================================================================
    
    // The number of DMA blocks remaining to read
    reg[31:0]               blocks_remaining; 
    
    assign BLOCKS_IN_FIFO = blocks_in_fifo;

    always @(posedge AXI_ACLK) begin

        amci00_read <= 0;
 
        // Every time a block of data gets pulled out of the FIFO and written to the 
        // AXI destination, decrement the count of data-blocks that are in the FIFO.
        if (write_burst_complete && blocks_in_fifo) blocks_in_fifo <= blocks_in_fifo - 1;

        if (AXI_ARESETN == 0) begin
            dma_state <= 0;
            blocks_in_fifo <= 0;
        end else case(dma_state)
        
            // Here we are waiting for the signal to begin a DMA transfer.  When that
            // signal arrives, start the read of the first block of data.
            0:  if (start_dma) begin
                    blocks_remaining <= register[REG_COUNT] - 1;
                    amci00_raddr     <= {register[REG_SRC_H], register[REG_SRC_L]} + AXI_SRC_ADDR_OFFSET;
                    amci00_read      <= 1;
                    dma_state        <= 1;
                end

            // Here we wait for the AXI read of the block of data to complete.  
            1:  if (amci00_ridle) begin
                    
                    // If there are still data blocks remaining to be read in...
                    if (blocks_remaining) begin
                        blocks_remaining <= blocks_remaining - 1;
                        amci00_raddr     <= amci00_raddr + BLOCK_SIZE;
                        
                        if (blocks_in_fifo == 0)  // If there is room in the FIFO...
                            amci00_read <= 1;     //   Start reading the next block of data
                        else                      // Otherwise...
                            dma_state <=2;        //   Go wait for there to be room in the FIFO
                    end
                    
                    // Otherwise, there are no more blocks to be read in.  Go wait for the
                    // write-data-to-destination half of this engine to finish writing data
                    else dma_state <= 3;

                    // And there is now one more block in the FIFO
                    blocks_in_fifo <= blocks_in_fifo + 1;

                end

            // Here we're waiting for there to be sufficient free room in the FIFO
            // for us to store another block of data.  Once there is room to store 
            // that data, start the read.
            2:  if (blocks_in_fifo < 2) begin
                    amci00_read <= 1;
                    dma_state   <= 1;
                end

            // Here we are waiting for the "write-data-to-destination" half of the DMA
            // engine to finish writing data.  Once that is complete, this DMA transfer
            // is done
            3:  if (blocks_in_fifo == 0) dma_state <= 0;
                   

        endcase
    end
    //=========================================================================================================




    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //              Application-specific logic for handling read/writes to the slave interface 
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    
    //=========================================================================================================
    // State machine that handles AXI master reads of our AXI4-Lite slave registers
    //
    // When user_read_start goes high, this state machine should handle the read-request.
    //    s_axi_araddr = The byte address of the register to read
    //
    // When read operation is complete:
    //    user_read_idle = 1
    //    s_axi_rresp     = OKAY/SLVERR response to send to the requesting master
    //    s_axi_rdata     = The read-data to send back to the requesting master
    //=========================================================================================================
    always @(posedge AXI_ACLK) begin

        if (AXI_ARESETN == 0) begin
            user_read_idle <= 1;
        end else if (user_read_start) begin
            
            // By default, we'll return a read-response of OKAY
            s_axi_rresp    <= OKAY;     
            
            // Turn the read-address into a register number
            case(s_axi_araddr >> 2)
                
                // Handle reads of legitimate register addresses
                REG_SRC_H:    s_axi_rdata <= register[REG_SRC_H];
                REG_SRC_L:    s_axi_rdata <= register[REG_SRC_L];
                REG_DST_H:    s_axi_rdata <= register[REG_DST_H];
                REG_DST_L:    s_axi_rdata <= register[REG_DST_L];
                REG_COUNT:    s_axi_rdata <= register[REG_COUNT];
                REG_CTL_STAT: s_axi_rdata <= is_dma_engine_idle;
                
                // A read of an unknown register results in a SLVERR response
                default:      begin
                                  s_axi_rdata    <= 32'h0DEC0DE0;
                                  s_axi_rresp    <= SLVERR;
                              end
            endcase
        end
    end
    //=========================================================================================================
    

    //=========================================================================================================
    // State machine that handles AXI master writes to our AXI4-Lite slave registers
    //
    // When user_write_start goes high, this state machine should handle the write-request.
    //    s_axi_awaddr = The byte address of the register to write to
    //    s_axi_wdata  = The 32-bit word to write into that register
    //
    // When write operation is complete:
    //    user_write_idle = 1
    //    s_axi_bresp     = OKAY/SLVERR response to send to the requesting master
    //=========================================================================================================

    always @(posedge AXI_ACLK) begin

        // When start_dma gets set to 1, ensure that it's a one-clock-cycle pulse
        start_dma <= 0;

        if (AXI_ARESETN == 0) begin
            user_write_idle <= 1;
        end else if (user_write_start) begin
            
            // By default, we'll return a write-response of OKAY
            s_axi_bresp    <= OKAY;     
            
            // Turn the write-address into a register number
            case(s_axi_awaddr >> 2)
                
                // Handle writes to legitimate register addresses
                REG_SRC_H:    register[REG_SRC_H] <= s_axi_wdata;
                REG_SRC_L:    register[REG_SRC_L] <= s_axi_wdata; 
                REG_DST_H:    register[REG_DST_H] <= s_axi_wdata;
                REG_DST_L:    register[REG_DST_L] <= s_axi_wdata;
                REG_COUNT:    register[REG_COUNT] <= s_axi_wdata;

                // Any write to the control/status register starts a DMA transfer
                REG_CTL_STAT: begin
                                register[REG_SRC_H] <= 0;
                                register[REG_SRC_L] <= 32'hC000_0000;
                                register[REG_DST_H] <= 0;
                                register[REG_DST_L] <= 0;
                                register[REG_COUNT] <= 5;
                                start_dma <= (is_dma_engine_idle);
                                //? GOOD LINE start_dma <= (is_dma_engine_idle && register[REG_COUNT] > 0);
                              end
                
                // A write to an unknown register results in a SLVERR response
                default:      s_axi_bresp <= SLVERR;
                              
            endcase
        end
    end

    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                           End of AXI slave read/write handlers
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><



    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //    This is the FIFO that serves as buffer between the read-from-source DMA state-machine and the
    //    write-to-destination  DMA state-machine
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    xpm_fifo_sync #
    (
      .CASCADE_HEIGHT       (0),       
      .DOUT_RESET_VALUE     ("0"),    
      .ECC_MODE             ("no_ecc"),       
      .FIFO_MEMORY_TYPE     ("auto"), 
      .FIFO_READ_LATENCY    (1),     
      .FIFO_WRITE_DEPTH     (BEATS_PER_BURST * 2),    
      .FULL_RESET_VALUE     (0),      
      .PROG_EMPTY_THRESH    (1),    
      .PROG_FULL_THRESH     (1),     
      .RD_DATA_COUNT_WIDTH  (1),   
      .READ_DATA_WIDTH      (AXI_DATA_WIDTH),
      .READ_MODE            ("fwft"),         
      .SIM_ASSERT_CHK       (0),        
      .USE_ADV_FEATURES     ("1010"), 
      .WAKEUP_TIME          (0),           
      .WRITE_DATA_WIDTH     (AXI_DATA_WIDTH), 
      .WR_DATA_COUNT_WIDTH  (1)    

      //------------------------------------------------------------
      // These exist only in xpm_fifo_async, not in xpm_fifo_sync
      //.CDC_SYNC_STAGES(2),       // DECIMAL
      //.RELATED_CLOCKS(0),        // DECIMAL
      //------------------------------------------------------------
    )
    xpm_dma_fifo
    (
        .rst        (RESET          ),                      
        .full       (fifo_full      ),              
        .din        (M00_AXI_RDATA  ),                 
        .wr_en      (fifo_write     ),            
        .wr_clk     (M_AXI_ACLK     ),          
        .data_valid (               ), 
        .dout       (M01_AXI_WDATA  ),              
        .empty      (fifo_empty     ),            
        .rd_en      (fifo_read      ),            

      //------------------------------------------------------------
      // This only exists in xpm_fifo_async, not in xpm_fifo_sync
      // .rd_clk    (CLK               ),                     
      //------------------------------------------------------------

        .sleep(),                        
        .injectdbiterr(),                
        .injectsbiterr(),                
        .overflow(),                     
        .prog_empty(),                   
        .prog_full(),                    
        .rd_data_count(),                
        .rd_rst_busy(),                  
        .sbiterr(),                      
        .underflow(),                    
        .wr_ack(WR_ACK),                       
        .wr_data_count(),                
        .wr_rst_busy(WR_RST_BUSY),                  
        .almost_empty(),                 
        .almost_full(),                  
        .dbiterr()                       
    );



endmodule




