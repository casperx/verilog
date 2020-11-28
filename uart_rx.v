module uart_rx #
(
	// number of clock cycles per single bit of UART transmission

	parameter	p_delay_cnt,

	// number of data bit expected

	parameter	p_bit_cnt = 4'd8
)
(
	input							i_clk,
	input							i_rst,

	input							i_sig,

	output	[ p_bit_cnt - 1 : 0 ]	o_fifo_wr_data,
	output							o_fifo_wr_en,

	input							i_fifo_full
);
	// UART signal shadow

	reg	r_sig;

	always @( posedge i_clk )

		r_sig <= i_sig;


	localparam	s_idle = 3'd0, s_start = 3'd1, s_data = 3'd2, s_stop = 3'd3, s_store = 3'd4;

	// current state

	reg	[ 2 : 0 ]	r_state;


	// data bit received

	reg	[ p_bit_cnt - 1 : 0 ]	r_bit;

	// number of data bit received

	reg	[ $clog2( p_bit_cnt ) : 0 ]	r_bit_cnt;


	// number of clock cycles to next event

	reg [ $clog2( p_delay_cnt ) : 0 ]	r_delay_cnt;


	assign	o_fifo_wr_data = r_bit;

	assign	o_fifo_wr_en = r_state == s_store;


	initial

		r_state <= s_idle;


	always @( posedge i_clk )

	begin

		if ( i_rst )

			r_state <= s_idle;

		else

			case ( r_state )

			s_idle: // wait for start bit

				if ( ~r_sig ) // falling edge of start bit

				begin

					r_state	<= s_start;

					r_delay_cnt <= p_delay_cnt / 2'd2;

				end

			s_start: // check start bit

				if ( r_delay_cnt == 1'd1 ) // right time to observe

				begin

					if ( ~r_sig ) // valid start bit

					begin

						r_state <= s_data;

						r_delay_cnt <= p_delay_cnt;


						r_bit_cnt <= p_bit_cnt;

					end

					else

						r_state <= s_idle;

				end

				else

					r_delay_cnt <= r_delay_cnt - 1'd1; // count time

			s_data: // capture data bit

				if ( r_delay_cnt == 1'd1 )

				begin

					r_delay_cnt <= p_delay_cnt;


					r_bit <= { r_sig, r_bit[ p_bit_cnt - 1 : 1 ] }; // shift bits


					if ( r_bit_cnt == 1'd1 )

						r_state <= s_stop;

					else

						r_bit_cnt <= r_bit_cnt - 1'd1; // count bit

				end

				else

					r_delay_cnt <= r_delay_cnt - 1'd1;

			s_stop: // check stop bit

				if ( r_delay_cnt == 1'd1 )

					if ( r_sig & ~i_fifo_full ) // valid stop bit

						r_state <= s_store;

					else

						r_state <= s_idle;

				else

					r_delay_cnt <= r_delay_cnt - 1'd1;

			s_store:

				r_state <= s_idle;

			endcase

	end

endmodule
