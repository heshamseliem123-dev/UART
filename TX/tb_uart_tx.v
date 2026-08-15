`timescale 1ns/1ps

module tb_uart_tx;

    // ---------------- DUT signals ----------------
    reg        CLK;
    reg        RST;
    reg        PAR_TYP;
    reg        PAR_EN;
    reg  [7:0] P_DATA;
    reg        DATA_VALID;
    wire       TX_OUT;
    wire       Busy;

    integer errors = 0;
    integer i;

    // ---------------- DUT instance ----------------
    uart_tx DUT (
        .CLK        (CLK),
        .RST        (RST),
        .PAR_TYP    (PAR_TYP),
        .PAR_EN     (PAR_EN),
        .P_DATA     (P_DATA),
        .DATA_VALID (DATA_VALID),
        .TX_OUT     (TX_OUT),
        .Busy       (Busy)
    );

    // ---------------- Clock: 200 MHz -> 5 ns period ----------------
    initial CLK = 1'b0;
    always #2.5 CLK = ~CLK;

    // ---------------- Dump waves ----------------
    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

    // ---------------- Task: send one byte and self-check the frame ----------------
    task send_byte;
        input [7:0] data;
        input       par_en;
        input       par_typ;
        reg         exp_parity;
        reg  [10:0] exp_frame; // [10]=start [9:2]=data(LSB..MSB) [1]=parity(if any) [0]=stop  (we'll check bit by bit instead)
        integer     bit_i;
        begin
            @(negedge CLK);
            P_DATA     = data;
            PAR_EN     = par_en;
            PAR_TYP    = par_typ;
            DATA_VALID = 1'b1;
            @(negedge CLK);
            DATA_VALID = 1'b0; // only 1 clock pulse, per spec
            // NOTE: the moment DATA_VALID drops (this same negedge) we are
            // already inside the START state, because the FSM transitioned
            // IDLE->START on the posedge that fell *while* DATA_VALID was
            // still high. So we check the start bit right here - no extra
            // @(negedge CLK) needed.

            // ---- check IDLE->START : TX_OUT must go to 0 (start bit) ----
            if (TX_OUT !== 1'b0) begin
                $display("[%0t] ERROR: start bit expected 0, got %b", $time, TX_OUT);
                errors = errors + 1;
            end
            if (Busy !== 1'b1) begin
                $display("[%0t] ERROR: Busy expected 1 during transmission", $time);
                errors = errors + 1;
            end

            // ---- check 8 data bits, LSB first ----
            for (bit_i = 0; bit_i < 8; bit_i = bit_i + 1) begin
                @(negedge CLK);
                if (TX_OUT !== data[bit_i]) begin
                    $display("[%0t] ERROR: data bit %0d expected %b got %b",
                              $time, bit_i, data[bit_i], TX_OUT);
                    errors = errors + 1;
                end
            end

            // ---- check parity bit (if enabled) ----
            if (par_en) begin
                exp_parity = par_typ ? ~(^data) : (^data);
                @(negedge CLK);
                if (TX_OUT !== exp_parity) begin
                    $display("[%0t] ERROR: parity bit expected %b got %b",
                              $time, exp_parity, TX_OUT);
                    errors = errors + 1;
                end
            end

            // ---- check stop bit ----
            @(negedge CLK);
            if (TX_OUT !== 1'b1) begin
                $display("[%0t] ERROR: stop bit expected 1, got %b", $time, TX_OUT);
                errors = errors + 1;
            end

            // ---- check back to IDLE ----
            @(negedge CLK);
            if (TX_OUT !== 1'b1 || Busy !== 1'b0) begin
                $display("[%0t] ERROR: expected IDLE (TX_OUT=1, Busy=0) got TX_OUT=%b Busy=%b",
                          $time, TX_OUT, Busy);
                errors = errors + 1;
            end

            $display("[%0t] PASS: byte=8'h%0h par_en=%0b par_typ=%0b sent correctly",
                       $time, data, par_en, par_typ);
        end
    endtask

    // ---------------- Stimulus ----------------
    initial begin
        // init
        RST        = 1'b0; // assert reset
        DATA_VALID = 1'b0;
        P_DATA     = 8'h00;
        PAR_EN     = 1'b0;
        PAR_TYP    = 1'b0;

        repeat (4) @(negedge CLK);
        RST = 1'b1; // release async reset
        @(negedge CLK);

        // sanity: idle levels
        if (TX_OUT !== 1'b1) begin
            $display("[%0t] ERROR: TX_OUT should idle-high after reset", $time);
            errors = errors + 1;
        end
        if (Busy !== 1'b0) begin
            $display("[%0t] ERROR: Busy should be low after reset", $time);
            errors = errors + 1;
        end

        // ---- Case 1: parity enabled, EVEN parity, from spec waveform (8'hA5) ----
        send_byte(8'hA5, 1'b1, 1'b0);

        // ---- Case 2: parity enabled, ODD parity ----
        send_byte(8'hF3, 1'b1, 1'b1);

        // ---- Case 3: parity disabled ----
        send_byte(8'h3C, 1'b0, 1'b0);

        // ---- Case 4: try to load new data while Busy (must be ignored) ----
        @(negedge CLK);
        P_DATA     = 8'h11;
        PAR_EN     = 1'b0;
        DATA_VALID = 1'b1;
        @(negedge CLK);
        DATA_VALID = 1'b0; // now inside START state, TX_OUT already = start bit(0)
        if (TX_OUT !== 1'b0) begin
            $display("[%0t] ERROR: (busy-reject test) start bit expected 0 got %b", $time, TX_OUT);
            errors = errors + 1;
        end
        // fire DATA_VALID again mid-frame (during data bit0) - must be ignored since Busy=1
        @(negedge CLK); // now on data bit0
        if (TX_OUT !== 1'b1) begin // bit0 of 8'h11 = 1
            $display("[%0t] ERROR: (busy-reject) bit0 expected 1 got %b", $time, TX_OUT);
            errors = errors + 1;
        end
        DATA_VALID = 1'b1;
        P_DATA     = 8'hFF; // this must NOT be the byte actually sent
        // verify remaining bits 1..7 still belong to the ORIGINAL byte 8'h11
        for (i = 1; i < 8; i = i + 1) begin
            @(negedge CLK);
            if (i == 1) DATA_VALID = 1'b0; // drop after exactly 1 clock, per spec
            if (TX_OUT !== ((8'h11 >> i) & 1'b1)) begin
                $display("[%0t] ERROR: (busy-reject) bit%0d expected %b got %b",
                          $time, i, ((8'h11 >> i) & 1'b1), TX_OUT);
                errors = errors + 1;
            end
        end
        @(negedge CLK); // stop bit
        if (TX_OUT !== 1'b1) begin
            $display("[%0t] ERROR: (busy-reject) stop bit expected 1 got %b", $time, TX_OUT);
            errors = errors + 1;
        end
        @(negedge CLK); // back to idle
        if (TX_OUT !== 1'b1 || Busy !== 1'b0) begin
            $display("[%0t] ERROR: (busy-reject) expected IDLE after original byte finished", $time);
            errors = errors + 1;
        end else begin
            $display("[%0t] PASS: DATA_VALID pulse during Busy was correctly ignored (8'h11 sent, not 8'hFF)", $time);
        end

        // ---- Case 5: async reset mid-transmission ----
        @(negedge CLK);
        P_DATA     = 8'h5A;
        PAR_EN     = 1'b1;
        PAR_TYP    = 1'b0;
        DATA_VALID = 1'b1;
        @(negedge CLK);
        DATA_VALID = 1'b0;
        repeat (3) @(negedge CLK); // reset while inside DATA state
        RST = 1'b0;
        @(negedge CLK);
        if (TX_OUT !== 1'b1 || Busy !== 1'b0) begin
            $display("[%0t] ERROR: async reset did not force IDLE immediately", $time);
            errors = errors + 1;
        end else begin
            $display("[%0t] PASS: async reset correctly forces IDLE mid-frame", $time);
        end
        RST = 1'b1;
        @(negedge CLK);

        // ---------------- summary ----------------
        if (errors == 0)
            $display("\n===== ALL TESTS PASSED =====");
        else
            $display("\n===== %0d TEST(S) FAILED =====", errors);
#220
        $finish;
    end

    // optional live monitor
    // initial $monitor("t=%0t state_bits(mux_sel not exposed) TX_OUT=%b Busy=%b", $time, TX_OUT, Busy);

endmodule
