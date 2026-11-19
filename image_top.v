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
	output wire is_bean);
	
	wire reset;
	assign reset = ~RESET_N;
	wire [7:0] rx_data;
	wire rx_done;
	reg [7:0] tx_data;
    reg tx_start;
    wire tx_busy;
	
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
	
	uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(9600)
    ) TX0 (
        .clk(CLOCK_50),
        .reset(reset),
        .tx_start(tx_start),
        .data_in(tx_data),
        .tx(UART_TX),
        .busy(tx_busy)
    );  

	//Recibe RGB
	reg [7:0] R;
	reg [7:0] G;
	reg [7:0] B;
	
	reg [2:0] state;
	reg rgb_valid;
	
	always @(posedge CLOCK_50 or posedge reset) begin
		if (reset) begin
			R <= 8'd0;
			G <= 8'd0;
			B <= 8'd0;
			state <= 2'd0;
			rgb_valid <= 1'b0;
		end else begin
			rgb_valid <= 1'b0;
			if (rx_done) begin      
				case (state)
					2'd0: begin //Rojo
						R <= rx_data;
						state <= 2'd1;
					end
					2'd1: begin //Verde
						G <= rx_data;
						state <= 2'd2;
					end
					2'd2: begin //Azul
						B <= rx_data;
						state <= 2'd0;
						rgb_valid <= 1'b1;
					end
					default: state <= 2'd0;
				endcase
			end
		end
	end
	//Procesa la imagen

	//Escala de grises (3 colores a gris)
	wire [7:0] gray;
	wire gray_valid;

	grayscale GRAY (.clk(CLOCK_50), .rst(reset), .valid(rgb_valid), .R(R), .G(G), .B(B), .valid_o(gray_valid), .gray(gray));

	wire pixel;
	wire thr_valid;

	thresholding THR (.clk(CLOCK_50), .rst(reset), .valid(gray_valid), .gray(gray), .valid_o(thr_valid), .pixel(pixel));

	wire pixel_o;
	wire valid_cont;

	contouring #(.WIDTH(WIDTH)) CONT (.clk(CLOCK_50), .rst(reset), .valid(thr_valid), .pixel(pixel), .valid_o(valid_cont), .pixel_o(pixel_o));

	//features
	//classify-> is_bean
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
    end
    else begin

        if (rgb_valid)
            contador_rgb <= contador_rgb + 1'b1;

        if (gray_valid)
            contador_gray <= contador_gray + 1'b1;

        if (thr_valid)
            contador_thr <= contador_thr + 1'b1;

        if (valid_cont)
            contador_cont <= contador_cont + 1'b1;

        if (tx_start)
            contador_tx <= contador_tx + 1'b1;

		end
	end
	
	
	
	//transmisi�n
	reg pending;
	reg pending_pixel;
	
	always@(posedge CLOCK_50 or posedge reset) begin
		if(reset) begin
			tx_data <= 8'd0;
			tx_start <= 1'b0;
			pending <= 1'b0;
			pending_pixel <= 1'b0;
		end
		else begin
			tx_start <= 1'b0;

			if (valid_cont) begin
				pending <= 1'b1;
				pending_pixel <= pixel_o;
			end

			if (!tx_busy && pending) begin
				tx_data <= pending_pixel ? 8'd255 : 8'd0;
				tx_start <= 1'b1;
				pending <= 1'b0;
			end
		end
	end
endmodule
