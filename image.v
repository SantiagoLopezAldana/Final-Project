module image #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128
)(
    input wire CLOCK_50,
    input wire RESET_N,
    input wire UART_RX,
    output wire UART_TX,
    output reg valid_o,
    output reg start_o,
    output reg [7:0] R,
    output reg [7:0] G,
    output reg [7:0] B
);
    localparam TOTAL_PIXELS = WIDTH * HEIGHT; // 16384 píxeles

    wire reset = ~RESET_N;
    assign UART_TX = 1'b1; // Línea TX en reposo (alto)

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

    reg [1:0] state;
    reg [14:0] pixel_cnt;

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            R <= 8'd0;
            G <= 8'd0;
            B <= 8'd0;
            state <= 2'd0;
            pixel_cnt <= 15'd0;
            valid_o <= 1'b0;
            start_o <= 1'b0;
        end else begin
            valid_o <= 1'b0;
            start_o <= 1'b0;

            if (rx_done) begin
                case (state)
                    2'd0: begin // Byte Rojo
                        R <= rx_data;
                        state <= 2'd1;
                        if (pixel_cnt == 15'd0)
                            start_o <= 1'b1; // Reinicia features al iniciar imagen
                    end
                    2'd1: begin // Byte Verde
                        G <= rx_data;
                        state <= 2'd2;
                    end
                    2'd2: begin // Byte Azul -> Píxel completo
                        B <= rx_data;
                        state <= 2'd0;
                        valid_o <= 1'b1;
                        if (pixel_cnt == TOTAL_PIXELS - 1)
                            pixel_cnt <= 15'd0;
                        else
                            pixel_cnt <= pixel_cnt + 15'd1;
                    end
                    default: state <= 2'd0;
                endcase
            end
        end
    end
endmodule

