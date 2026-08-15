// ============================================================
// Module : tx_mux
// Purpose: Picks what goes out on TX_OUT depending on which
//          part of the frame the FSM is currently sending.
// ============================================================
module tx_mux (
    input  wire [2:0] mux_sel,
    input  wire        ser_data,
    input  wire        par_bit,
    output reg         TX_OUT
);

    // Selector values (must match the encoding used inside fsm.v)
    localparam SEL_IDLE  = 3'd0;
    localparam SEL_START = 3'd1;
    localparam SEL_DATA  = 3'd2;
    localparam SEL_PAR   = 3'd3;
    localparam SEL_STOP  = 3'd4;

    always @(*) begin
        case (mux_sel)
            SEL_START: TX_OUT = 1'b0;      // start bit
            SEL_DATA : TX_OUT = ser_data;  // data bits, one per clock
            SEL_PAR  : TX_OUT = par_bit;   // parity bit
            SEL_STOP : TX_OUT = 1'b1;      // stop bit
            default  : TX_OUT = 1'b1;      // SEL_IDLE -> line idles high
        endcase
    end

endmodule
