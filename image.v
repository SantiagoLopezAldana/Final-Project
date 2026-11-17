//Py->UART->esp32->FPGA
module image(
	input wire CLOCK_50,
	input wire RESET_N,
	input wire UART_RX,
	output wire UART_TX
	output reg [7:0] R,
	output reg [7:0] G,
	output reg [7:0] B); //0-255 tono
	
	wire reset;
	assign reset = ~RESET_N;
	
	wire [7:0] rx_data;
	wire rx_done;
	

	uart_rx #(
		.CLK_FREQ(50000000),
		.BAUD_RATE(9600)
	) RX0 (
		.clk(CLOCK_50),
		.reset(reset),
		.rx(UART_RX),
		.data_out(rx_data),
		.data_valid(rx_done)
	);

	reg [2:0] state;       
	
	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
			R <= 8'd0;
			G <= 8'd0;
			B <= 8'd0;
			state <= 2'd0;
		end else begin
			if (rx_done) begin      
				case (state)
					2'd0: begin //Rojo
						R <= rx_data;
						state <= 2'd1;
					end
					2'd1: begin //verde
						G <= rx_data;
						state <= 2'd2;
					end
					2'd2: begin 
						B <= rx_data;
						state <= 2'd0;
					end
				endcase
			end
		end
	end
endmodule
