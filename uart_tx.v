module uart_tx #
(
	// number of clock cycles per single bit of UART transmission

	parameter	p_delay_cnt,

	// number of data bit sent

	parameter	p_bit_cnt = 4'd8
)
(
	input							i_clk,
	input							i_rst,

	output							o_sig,

	input	[ p_bit_cnt - 1 : 0 ]	i_fifo_rd_data,
	output							o_fifo_rd_en,

	input							i_fifo_empty
);
	localparam p_shift_cnt = p_bit_cnt + 2'd2;


	localparam	s_idle = 2'd0, s_req = 2'd1, s_init = 2'd2, s_shift = 2'd3;

	// current state

	reg	[ 1 : 0 ]	r_state;


	// bit to be sent

	reg	[ p_shift_cnt - 1 : 0 ]	r_shift;

	// number of bit to be sent, include start and stop bit

	reg	[ $clog2( p_shift_cnt ) : 0 ]	r_shift_cnt;


	// number of clock cycles to next event

	reg [ $clog2( p_delay_cnt ) : 0 ]	r_delay_cnt;


	assign	o_fifo_rd_en = r_state == s_req;


	initial

		r_state <= s_idle;


	always @( posedge i_clk )

	begin

		if ( i_rst )

			r_state <= s_idle;

		else

			case ( r_state )

			s_idle:

				if ( ~i_fifo_empty )

					r_state <= s_req;

			s_req:

				r_state <= s_init;

			s_init:

				begin

					r_state <= s_shift;

					r_delay_cnt <= p_delay_cnt;


					r_shift <= { 1'b1, i_fifo_rd_data, 1'b0 };

					r_shift_cnt <= p_shift_cnt;

				end

			s_shift:

				if ( r_delay_cnt == 1'd1 )

				begin

					r_delay_cnt <= p_delay_cnt;


					r_shift <= { 1'b1, r_shift[ p_shift_cnt - 1 : 1 ] }; // shift bit


					if ( r_shift_cnt == 1'd1 )

						r_state <= s_idle;

					else

						r_shift_cnt <= r_shift_cnt - 1'd1; // count bit

				end

				else

					r_delay_cnt <= r_delay_cnt - 1'd1;

			endcase

	end


	assign	o_sig = r_state == s_shift ? r_shift[ 0 ] : 1'b1;

endmodule