// ============================================================
// Module : uart_tx  (TOP)
// Spec   : UART_TX_Spec_Document
// ============================================================
module uart_tx (
    input  wire       CLK,
    input  wire       RST,        // asynchronous, ACTIVE LOW
    input  wire       PAR_TYP,    // 0 = even, 1 = odd
    input  wire       PAR_EN,     // 0 = disabled, 1 = enabled
    input  wire [7:0] P_DATA,
    input  wire       DATA_VALID,
    output wire       TX_OUT,
    output wire       Busy
);

    // ---------------- internal wires ----------------
    wire        load;
    wire        ser_en;
    wire        ser_done;
    wire        ser_data;
    wire [2:0]  mux_sel;
    wire        par_bit;
    

    // We need a *stable* snapshot of the byte for the parity
    // calculator (P_DATA itself may change right after DATA_VALID
    // drops). We reuse the same load pulse the serializer uses.
    reg [7:0] data_snapshot;
    always @(posedge CLK or negedge RST) begin
        if (!RST)
            data_snapshot <= 8'd0;
        else if (load)
            data_snapshot <= P_DATA;
    end

    // ---------------- FSM ----------------
    fsm u_fsm (
        .CLK            (CLK),
        .RST            (RST),
        .DATA_VALID     (DATA_VALID),
        .PAR_EN         (PAR_EN),
        .ser_done       (ser_done),
        .load           (load),
        .ser_en         (ser_en),
        .mux_sel        (mux_sel),
        .busy           (Busy)
        
    );

    // ---------------- Serializer ----------------
    serializer u_serializer (
        .CLK      (CLK),
        .RST      (RST),
        .load     (load),
        .ser_en   (ser_en),
        .data_in  (P_DATA),
        .ser_data (ser_data),
        .ser_done (ser_done)
    );

    // ---------------- Parity Calc ----------------
    parity_calc u_parity (
        .data    (data_snapshot),
        .par_typ (PAR_TYP),
        .par_bit (par_bit)
    );

    // ---------------- Output Mux ----------------
    tx_mux u_mux (
        .mux_sel  (mux_sel),
        .ser_data (ser_data),
        .par_bit  (par_bit),
        .TX_OUT   (TX_OUT)
    );

endmodule
