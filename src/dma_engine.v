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
    parameter integer AXI_DATA_WIDTH   = 512,
    parameter integer AXI_ADDR_WIDTH   =  64,
    parameter integer S_AXI_ADDR_WIDTH =   5,
    parameter integer S_AXI_DATA_WIDTH =  32  

)
(
    input wire  AXI_ACLK,
    input wire  AXI_ARESETN,

    output wire START_DMA, AMCI00_READ,

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
    input  wire                                              M00_AXI_RLAST
    //==========================================================================

/*
    //==========================================================================
    // This defines the AXI Master interface that connects to data destination
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
*/


 );

    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                           This section is standard AXI4 Master logic
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><



    localparam M00_AXI_DATA_BYTES = (AXI_DATA_WIDTH/8);

    // Assign all of the "write transaction" signals that aren't in the AXI4-Lite spec
    assign M00_AXI_AWID    = 1;   // Arbitrary ID
    assign M00_AXI_AWLEN   = 0;   // Burst length of 1
    assign M00_AXI_AWSIZE  = 2;   // 2 = 4 bytes per burst (assuming a 32-bit AXI data-bus)
    assign M00_AXI_WLAST   = 1;   // Each beat is always the last beat of the burst
    assign M00_AXI_AWBURST = 1;   // Each beat of the burst increments by 1 address (ignored)
    assign M00_AXI_AWLOCK  = 0;   // Normal signaling
    assign M00_AXI_AWCACHE = 2;   // Normal, no cache, no buffer
    assign M00_AXI_AWQOS   = 0;   // Lowest quality of service, unused

    // Assign all of the "read transaction" signals that aren't in the AXI4-Lite spec
    assign M00_AXI_ARLOCK  = 0;   // Normal signaling
    assign M00_AXI_ARID    = 1;   // Arbitrary ID
    assign M00_AXI_ARBURST = 1;   // Increment address on each beat of the burst (unused)
    assign M00_AXI_ARCACHE = 2;   // Normal, no cache, no buffer
    assign M00_AXI_ARQOS   = 0;   // Lowest quality of service (unused)

    // Define the handshakes for all 5 master AXI channels
    wire M00_B_HANDSHAKE  = M00_AXI_BVALID  & M00_AXI_BREADY;
    wire M00_R_HANDSHAKE  = M00_AXI_RVALID  & M00_AXI_RREADY;
    wire M00_W_HANDSHAKE  = M00_AXI_WVALID  & M00_AXI_WREADY;
    wire M00_AR_HANDSHAKE = M00_AXI_ARVALID & M00_AXI_ARREADY;
    wire M00_AW_HANDSHAKE = M00_AXI_AWVALID & M00_AXI_AWREADY;

    //=========================================================================================================
    // FSM logic used for writing to the slave device.
    //
    //  To start:   amci00_waddr = Address to write to
    //              amci00_wdata = Data to write at that address
    //              amci00_write = Pulsed high for one cycle
    //
    //  At end:     Write is complete when "amci00_widle" goes high
    //              amci00_wresp = AXI_BRESP "write response" signal from slave
    //=========================================================================================================
    reg[1:0]                m00_write_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0] amci00_waddr;
    reg[AXI_DATA_WIDTH-1:0] amci00_wdata;
    reg                     amci00_write;

    // FSM user interface outputs
    wire     amci00_widle = (m00_write_state == 0 && amci00_write == 0);     
    reg[1:0] amci00_wresp;

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0] m00_axi_awaddr;
    reg[AXI_DATA_WIDTH-1:0] m00_axi_wdata;
    reg                     m00_axi_awvalid = 0;
    reg                     m00_axi_wvalid = 0;
    reg                     m00_axi_bready = 0;

    // Wire up the AXI interface outputs
    assign M00_AXI_AWADDR  = m00_axi_awaddr;
    assign M00_AXI_WDATA   = m00_axi_wdata;
    assign M00_AXI_AWVALID = m00_axi_awvalid;
    assign M00_AXI_WVALID  = m00_axi_wvalid;
    assign M00_AXI_AWPROT  = 3'b000;
    assign M00_AXI_WSTRB   = (1 << M00_AXI_DATA_BYTES) - 1; // usually 4'b1111
    assign M00_AXI_BREADY  = m00_axi_bready;
    //=========================================================================================================
     
    always @(posedge AXI_ACLK) begin

        // If we're in RESET mode...
        if (AXI_ARESETN == 0) begin
            m00_write_state <= 0;
            m00_axi_awvalid <= 0;
            m00_axi_wvalid  <= 0;
            m00_axi_bready  <= 0;
        end        
        
        // Otherwise, we're not in RESET and our state machine is running
        else case (m00_write_state)
            
            // Here we're idle, waiting for someone to raise the 'amci00_write' flag.  Once that happens,
            // we'll place the user specified address and data onto the AXI bus, along with the flags that
            // indicate that the address and data values are valid
            0:  if (amci00_write) begin
                    m00_axi_awaddr  <= amci00_waddr;  // Place our address onto the bus
                    m00_axi_wdata   <= amci00_wdata;  // Place our data onto the bus
                    m00_axi_awvalid <= 1;             // Indicate that the address is valid
                    m00_axi_wvalid  <= 1;             // Indicate that the data is valid
                    m00_axi_bready  <= 1;             // Indicate that we're ready for the slave to respond
                    m00_write_state <= 1;             // On the next clock cycle, we'll be in the next state
                end
                
           // Here, we're waiting around for the slave to acknowledge our request by asserting M00_AXI_AWREADY
           // and M00_AXI_WREADY.  Once that happens, we'll de-assert the "valid" lines.  Keep in mind that we
           // don't know what order AWREADY and WREADY will come in, and they could both come at the same
           // time.      
           1:   begin   
                    // Keep track of whether we have seen the slave raise AWREADY or WREADY
                    if (M00_AW_HANDSHAKE) m00_axi_awvalid <= 0;
                    if (M00_W_HANDSHAKE ) m00_axi_wvalid  <= 0;

                    // If we've seen AWREADY (or if its raised now) and if we've seen WREADY (or if it's raised now)...
                    if ((~m00_axi_awvalid || M00_AW_HANDSHAKE) && (~m00_axi_wvalid || M00_W_HANDSHAKE)) begin
                        m00_write_state <= 2;
                    end
                end
                
           // Wait around for the slave to assert "M00_AXI_BVALID".  When it does, we'll acknowledge
           // it by raising M00_AXI_BREADY for one cycle, and go back to idle state
           2:   if (M00_B_HANDSHAKE) begin
                    amci00_wresp  <= M00_AXI_BRESP;
                    m00_axi_bready  <= 0;
                    m00_write_state <= 0;
                end

        endcase
    end
    //=========================================================================================================





    //=========================================================================================================
    // FSM logic used for reading from a slave device.
    //
    //  To start:   amci00_raddr = Address to read from
    //              amci00_rsize = Code that indicates how many bytes wide a single beat is
    //              amci00_rlen  = How many "beats" (i.e., data words) to read after the first
    //              amci00_read  = Pulsed high for one cycle
    //
    //  At end:   Read is complete when "amci00_ridle" goes high.
    //            amci00_rdata = The data that was read
    //            amci00_rresp = The AXI "read response" that is used to indicate success or failure
    //=========================================================================================================
    reg                     m00_read_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0] amci00_raddr;
    reg[2:0]                amci00_rsize;
    reg[7:0]                amci00_rlen;
    reg                     amci00_read;

    // FSM user interface outputs
    reg[AXI_DATA_WIDTH-1:0] amci00_rdata;
    reg[1:0]                amci00_rresp;
    wire                    amci00_ridle = (m00_read_state == 0 && amci00_read == 0);     

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0] m00_axi_araddr;
    reg                     m00_axi_arvalid;
    reg[7:0]                m00_axi_arlen;
    reg[2:0]                m00_axi_arsize;
    reg                     m00_axi_rready;
    

    // Wire up the AXI interface outputs
    assign M00_AXI_ARADDR  = m00_axi_araddr;
    assign M00_AXI_ARVALID = m00_axi_arvalid;
    assign M00_AXI_ARPROT  = 3'b001;
    assign M00_AXI_ARLEN   = m00_axi_arlen;
    assign M00_AXI_ARSIZE  = m00_axi_arsize;
    assign M00_AXI_RREADY  = m00_axi_rready;
    //=========================================================================================================
    always @(posedge AXI_ACLK) begin
         
        if (AXI_ARESETN == 0) begin
            m00_read_state  <= 0;
            m00_axi_arvalid <= 0;
            m00_axi_rready  <= 0;
        end else case (m00_read_state)

            // Here we are waiting around for someone to raise "amci00_read", which signals us to begin
            // a AXI read at the address specified in "amci00_raddr"
            0:  if (amci00_read) begin
                    m00_axi_araddr  <= amci00_raddr;
                    m00_axi_arsize  <= amci00_rsize;
                    m00_axi_arlen   <= amci00_rlen;
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

                    if (M00_R_HANDSHAKE) begin
                        amci00_rdata  <= M00_AXI_RDATA;
                        amci00_rresp  <= M00_AXI_RRESP;
                        if (M00_AXI_RLAST) begin
                            m00_axi_rready <= 0;
                            m00_read_state <= 0;
                        end
                    end
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


    // This is the number of bytes in a burst.  Since AXI bursts aren't allowed to cross
    // 4096-byte boundaries, 4096 is the maximum number of bytes in a single burst
    localparam BLOCK_SIZE      = 4096;   

    // These calculations assume AXI_DATA_WIDTH is a power of 2
    localparam BYTES_PER_BEAT  = AXI_DATA_WIDTH / 8;
    localparam BEATS_PER_BURST = BLOCK_SIZE / BYTES_PER_BEAT;
    localparam AxSIZE          = $clog2(BYTES_PER_BEAT);  
    localparam WSTRB           = (1 << BYTES_PER_BEAT) - 1;

    reg start_dma;

    assign START_DMA = start_dma;
    assign AMCI00_READ = amci00_read;

    reg[3:0] state;
    always @(posedge AXI_ACLK) begin
        amci00_read <= 0;
        if (AXI_ARESETN == 0) begin
            state <= 0;
        end else case(state)
            0:  if (start_dma) begin
                    amci00_raddr <= 32'hC000_0000;
                    amci00_rsize <= AxSIZE;
                    amci00_rlen  <= BEATS_PER_BURST-1;
                    amci00_read  <= 1;
                    state        <= 1;
                end

            1:  if (amci00_ridle) state <= 0;
        endcase
    end




    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //              Application-specific logic for handling read/writes to the slave interface 
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

    localparam REG_SRC_H    = 0;    // Hi word of the DMA source address
    localparam REG_SRC_L    = 1;    // Lo word of the DMA source address
    localparam REG_DST_H    = 2;    // Hi word of the DMA destination address
    localparam REG_DST_L    = 3;    // Lo word of the DMA destination address
    localparam REG_COUNT    = 4;    // Number of 4K blocks to DMA transfer
    localparam REG_CTL_STAT = 5;    // Combined control and status register

    // Storage for the above registers.  (We don't actually store CTL_STAT)    
    reg [31:0] register[0:4];
    
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
        end else begin
            s_axi_rresp    <= OKAY;     // By default, we'll return a read-response of OKAY
            
            // Turn the read-address into a register number
            case(s_axi_araddr >> 2)
                
                // Handle reads of legitimate register addresses
                REG_SRC_H:    s_axi_rdata <= register[REG_SRC_H];
                REG_SRC_L:    s_axi_rdata <= register[REG_SRC_L];
                REG_DST_H:    s_axi_rdata <= register[REG_DST_H];
                REG_DST_L:    s_axi_rdata <= register[REG_DST_L];
                REG_COUNT:    s_axi_rdata <= register[REG_COUNT];
                REG_CTL_STAT: s_axi_rdata <= 42;
                
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
        end else begin
            s_axi_bresp    <= OKAY;     // By default, we'll return a write-response of OKAY
            
            // Turn the write-address into a register number
            case(s_axi_awaddr >> 2)
                
                // Handle writes to legitimate register addresses
                REG_SRC_H:    register[REG_SRC_H] <= s_axi_wdata;
                REG_SRC_L:    register[REG_SRC_L] <= s_axi_wdata; 
                REG_DST_H:    register[REG_DST_H] <= s_axi_wdata;
                REG_DST_L:    register[REG_DST_L] <= s_axi_wdata;
                REG_COUNT:    register[REG_COUNT] <= s_axi_wdata;

                // Any write to the control/status register starts a DMA transfer
                REG_CTL_STAT: start_dma <= 1;
                
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


endmodule




