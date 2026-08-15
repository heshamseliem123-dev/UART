// ============================================================
// Module : serializer
// Purpose: Holds the byte to be transmitted and exposes it
//          bit-by-bit (LSB first) to the mux, one bit per clock.
// ============================================================
module serializer (
    input  wire       CLK,
    input  wire        RST,      // async active low
    input  wire        load,     // pulse: capture data_in, restart bit index at 0
    input  wire        ser_en,   // 1 clock pulse per bit while FSM is in DATA state
    input  wire [7:0]  data_in,
    output wire        ser_data, // current bit to send (combinational read of data_reg)
    output wire        ser_done  // high during the LAST bit (bit index 7)
);

    reg [7:0] data_reg;   // snapshot of the byte being shifted out
    reg [2:0] bit_index;  // which bit (0..7) is currently on ser_data

    // ser_data always shows the bit pointed to by bit_index.
    // Nothing is physically "shifted" here - we just walk an index.
    // (This is functionally identical to shifting right each cycle,
    //  but easier to read/debug.)
    assign ser_data = data_reg[bit_index];
    assign ser_done = (bit_index == 3'd7);

    always @(posedge CLK or negedge RST) begin
        if (!RST) begin
            data_reg  <= 8'd0;
            bit_index <= 3'd0;
        end else if (load) begin
            data_reg  <= data_in;   // grab the byte
            bit_index <= 3'd0;      // start from bit0 (LSB first)
        end else if (ser_en) begin
            bit_index <= bit_index + 3'd1; // move to next bit each clock
        end
    end

endmodule
