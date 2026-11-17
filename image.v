module image(
	input wire CLOCK_50,
	input wire RESET_N,
	input wire UART_RX,
	output wire UART_TX
	output reg [7:0] R,
	output reg [7:0] G,
	output reg [7:0] B);
	
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
			tx_data <= 8'd0;
			tx_start <= 1'b0;
			tx_state <= 2'd0;
			data_to_send <= 32'd0;
			tx_busy_prev <= 1'b0;
		end else begin
			tx_busy_prev <= tx_busy;//estado anterior
			tx_start <= 1'b0;        
			
			case (state)
				2'd0: begin 
					if (rx_done && !tx_busy) begin
						data <= resultado;    
						tx_data <= data[31:24];//Byte 4
						tx_start <= 1'b1;                 
						tx_state <= 2'd1;                 
					end
				end
				
				2'd1: begin 
					if (tx_busy_prev && !tx_busy) begin
						tx_data <= data[23:16];//Byte 3
						tx_start <= 1'b1;
						tx_state <= 2'd2;
					end
				end
				
				2'd2: begin 
					if (tx_busy_prev && !tx_busy) begin
						tx_data <= data[15:8];//Byte 2
						tx_start <= 1'b1;
						tx_state <= 2'd3;
					end
				end
				
				2'd3: begin 
					if (tx_busy_prev && !tx_busy) begin
						tx_data <= data[7:0];//Byte 1
						tx_start <= 1'b1;
						tx_state <= 2'd0;           
					end
				end
			endcase
		end
	end
endmodule