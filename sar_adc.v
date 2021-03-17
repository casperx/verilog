module sar_adc #
(
    // adc bits
    parameter p_bit_cnt = 8
)
(
    input i_clk,
    input i_reset,

    // control port
    input  i_start,
    output o_busy,

    // result port
    output [p_bit_cnt - 1:0] o_res,
    output                   o_valid,

    // ports for DAC and comparator
    output [p_bit_cnt - 1:0] o_dac,
    input                    i_cmp
);
    localparam p_top_bit = p_bit_cnt - 1;

    // states
    localparam s_idle = 2'b0, s_samp = 2'b1, s_conv = 2'b2, s_done = 2'b3;

    reg [1:0] r_state;

    reg [p_bit_cnt - 1:0] r_cur, r_res;

    wire w_last = r_res[0];

    assign o_busy = r_state == s_samp | r_state == s_conv;

    assign o_res = r_res;
    assign o_valid = r_state == s_done;

    assign o_dac = r_res | r_cur;

    initial

        r_state <= s_idle;

    always @(posedge i_clk)

    begin

        if (i_reset)

            r_state <= s_idle;

        else

        begin

            case (r_state)

            s_idle, s_done:

                if (i_start)

                    r_state <= s_samp;

            s_samp:

            begin

                r_state <= s_conv;

                r_cur <= 1 << p_bit_cnt;

                r_res <= 0;

            end

            s_conv:

            begin

                if (i_cmp)

                    r_res <= r_res | r_cur;

                r_cur <= r_cur >> 1;

                if (w_last) r_state <= s_done;

            end

            endcase

        end

    end

endmodule
