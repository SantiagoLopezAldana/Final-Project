//Py->esp32 (UART), 49152 bytes->FPGA->esp32 (UART), 16385 bytes->Py

//128x128px: 491520 bits rx     9600: 51.2s       115200: 4.27s
//100x100px: 300000 bits rx     9600: 31.25s      115200: 2.6s
//75x75px:   168759 bits rx     9600: 17.6s       115200: 1.46s
//50x50px:   75000  bits rx     9600: 7.8s        115200: 0.65s
module image_top #(parameter WIDTH = 128, parameter HEIGHT = 128)(
	input wire CLOCK_50,
	input wire RESET_N,
	input wire UART_RX,
	output wire UART_TX,
	output wire is_bean
);
	localparam TOTAL_PIXELS = WIDTH * HEIGHT; // 16384 píxeles

	wire reset;
	assign reset = ~RESET_N;
	wire [7:0] rx_data;
	wire rx_done;
	reg [7:0] tx_data;
	reg tx_start;
	wire tx_busy;
	
	uart_rx #(
		.CLK_FREQ(50000000),
		.BAUD_RATE(115200)
	) RX0 (
		.clk(CLOCK_50),
		.reset(reset),
		.rx(UART_RX),
		.data_out(rx_data),
		.data_valid(rx_done)
	);
	
	uart_tx #(
		.CLK_FREQ(50000000),
		.BAUD_RATE(115200)
	) TX0 (
		.clk(CLOCK_50),
		.reset(reset),
		.tx_start(tx_start),
		.data_in(tx_data),
		.tx(UART_TX),
		.busy(tx_busy)
	);  

	// Recibe RGB y genera pulso de inicio por cada imagen
	reg [7:0] R;
	reg [7:0] G;
	reg [7:0] B;
	reg [1:0] state;
	reg rgb_valid;
	reg img_start;
	reg [14:0] rx_pixel_cnt;
	
	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
			R <= 8'd0;
			G <= 8'd0;
			B <= 8'd0;
			state <= 2'd0;
			rgb_valid <= 1'b0;
			img_start <= 1'b0;
			rx_pixel_cnt <= 15'd0;
		end else begin
			rgb_valid <= 1'b0;
			img_start <= 1'b0;

			if (rx_done) begin      
				case (state)
					2'd0: begin // Rojo
						R <= rx_data;
						state <= 2'd1;
						if (rx_pixel_cnt == 15'd0)
							img_start <= 1'b1; // Reinicia features al iniciar imagen
					end
					2'd1: begin // Verde
						G <= rx_data;
						state <= 2'd2;
					end
					2'd2: begin // Azul -> Píxel completo
						B <= rx_data;
						state <= 2'd0;
						rgb_valid <= 1'b1;
						if (rx_pixel_cnt == TOTAL_PIXELS - 1)
							rx_pixel_cnt <= 15'd0;
						else
							rx_pixel_cnt <= rx_pixel_cnt + 15'd1;
					end
					default: state <= 2'd0;
				endcase
			end
		end
	end

	// Procesa la imagen
	wire [7:0] gray;
	wire gray_valid;
	grayscale GRAY (
		.clk(CLOCK_50), .rst(reset), .valid(rgb_valid),
		.R(R), .G(G), .B(B), .valid_o(gray_valid), .gray(gray)
	);

	wire pixel;
	wire thr_valid;
	thresholding THR (
		.clk(CLOCK_50), .rst(reset), .valid(gray_valid),
		.gray(gray), .valid_o(thr_valid), .pixel(pixel)
	);

	wire pixel_o;
	wire valid_cont;
	contouring #(.WIDTH(WIDTH)) CONT (
		.clk(CLOCK_50), .rst(reset), .valid(thr_valid),
		.pixel(pixel), .valid_o(valid_cont), .pixel_o(pixel_o)
	);

	// Extracción de características
	wire feat_done;
	wire [14:0] area;
	wire [16:0] perimeter;
	wire [7:0] w, h, cx, cy;

	features #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) FEAT (
		.clk(CLOCK_50), .rst(reset), .start(img_start),
		.valid(valid_cont), .pixel(pixel_o),
		.done(feat_done), .area(area), .perimeter(perimeter),
		.w(w), .h(h), .cx(cx), .cy(cy)
	);

	// Clasificación final -> is_bean
	wire result_valid;

	classify #(
		.AREA_MIN(1500), .AREA_MAX(6000),
		.PERIM_MIN(150), .PERIM_MAX(500),
		.AR_MIN(20),     .AR_MAX(40),
		.CX_MIN(24),     .CX_MAX(104),
		.CY_MIN(24),     .CY_MAX(104)
	) CLS (
		.clk(CLOCK_50), .rst(reset), .done(feat_done),
		.area(area), .perimeter(perimeter),
		.w(w), .h(h), .cx(cx), .cy(cy),
		.result_valid(result_valid), .is_bean(is_bean)
	);

	// Contadores de depuración (Signal Tap)
	reg [14:0] contador_cont;
	reg [14:0] contador_tx;
	reg [14:0] contador_rgb;
	reg [14:0] contador_gray;
	reg [14:0] contador_thr;

	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
			contador_rgb  <= 0;
			contador_gray <= 0;
			contador_thr  <= 0;
			contador_cont <= 0;
			contador_tx   <= 0;
		end else begin
			if (rgb_valid)  contador_rgb  <= contador_rgb + 1'b1;
			if (gray_valid) contador_gray <= contador_gray + 1'b1;
			if (thr_valid)  contador_thr  <= contador_thr + 1'b1;
			if (valid_cont) contador_cont <= contador_cont + 1'b1;
			if (tx_start)   contador_tx   <= contador_tx + 1'b1;
		end
	end
	
	// Transmisión: 16,384 píxeles + 1 byte con resultado is_bean
	reg pending;
	reg pending_pixel;
	reg pending_cls;
	
	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
			tx_data <= 8'd0;
			tx_start <= 1'b0;
			pending <= 1'b0;
			pending_pixel <= 1'b0;
			pending_cls <= 1'b0;
		end else begin
			tx_start <= 1'b0;

			if (valid_cont) begin
				pending <= 1'b1;
				pending_pixel <= pixel_o;
			end

			if (result_valid) begin
				pending_cls <= 1'b1;
			end

			if (!tx_busy) begin
				if (pending) begin
					tx_data <= pending_pixel ? 8'd255 : 8'd0;
					tx_start <= 1'b1;
					pending <= 1'b0;
				end else if (pending_cls) begin
					tx_data <= {7'd0, is_bean};
					tx_start <= 1'b1;
					pending_cls <= 1'b0;
				end
			end
		end
	end
endmodule

