// ============================================================
// Module : fsm
// Purpose: Sequences the UART frame: IDLE -> START -> DATA(x8)
//          -> [PARITY] -> STOP -> IDLE
//          NOTE: CLK here IS the bit-rate clock (no baud
//          generator is required by this spec), so every
//          state except DATA lasts exactly 1 clock cycle.
// ============================================================
module fsm (
    input  wire       CLK,
    input  wire       RST,        // async active low
    input  wire       DATA_VALID,
    input  wire       PAR_EN,
    input  wire       ser_done,   // from serializer: high on last data bit

    output reg        load,       // pulse to serializer: capture new byte
    output reg        ser_en,     // pulse to serializer: advance one bit
    output reg [2:0]  mux_sel,
    output reg        busy
    
);

    // ---- state encoding (same values as SEL_* in tx_mux.v) ----
    localparam IDLE   = 3'd0;
    localparam START  = 3'd1;
    localparam DATA   = 3'd2;
    localparam PARITY = 3'd3;
    localparam STOP   = 3'd4;

    reg [2:0] state, next_state;
   reg        par_en_latched ;

    // ---------------- state register ----------------
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            state <= IDLE;
        else
            state <= next_state;
    end

    // latch PAR_EN at the moment we accept a new byte, so a change
    // on PAR_EN mid-frame can't corrupt the frame we're already sending
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            par_en_latched <= 1'b0;
        else if (state == IDLE && DATA_VALID)
            par_en_latched <= PAR_EN;
    end

    // ---------------- next state logic ----------------
    always @(*) begin
        next_state = state;
        case (state)
            IDLE : if (DATA_VALID) next_state = START;
            START: next_state = DATA;
            DATA : if (ser_done)   next_state = par_en_latched  ? PARITY : STOP;
            PARITY: next_state = STOP;
            STOP : next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ---------------- Moore outputs ----------------
    always @(*) begin
        load    = 1'b0;
        ser_en  = 1'b0;
        busy    = 1'b1;
        mux_sel = state; // encodings line up 1:1 with SEL_* in tx_mux

        case (state)
            IDLE : begin
                busy = 1'b0;
                load = DATA_VALID; // capture the byte the same cycle it arrives
            end
            START: begin
                // nothing extra - just outputs the start bit for 1 cycle
            end
            DATA : begin
                ser_en = 1'b1; // step the serializer's bit index each cycle
            end
            PARITY, STOP: begin
                // outputs held for 1 cycle each
            end
            default: ;
        endcase
    end

endmodule
