// ============================================================
// Module : parity_calc
// Purpose: Combinationally compute the parity bit for the byte.
//          PAR_TYP = 0 -> even parity
//          PAR_TYP = 1 -> odd  parity
// ============================================================
module parity_calc (
    input  wire [7:0] data,
    input  wire       par_typ,
    output wire        par_bit
);

    // ^data = XOR reduction = 1 if data has an ODD number of 1's.
    // Even parity bit  = ^data            (makes total ones even)
    // Odd  parity bit  = ~(^data)         (makes total ones odd)
    assign par_bit = par_typ ? ~(^data) : (^data);

endmodule
