module bean_top #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128,
    parameter AREA_MIN = 400,
    parameter AREA_MAX = 2500,
    parameter PERIM_MIN = 70,
    parameter PERIM_MAX = 220,
    parameter AR_MIN = 20,
    parameter AR_MAX = 40)(
    input wire CLOCK_50,
    input wire RESET_N,
    input wire UART_RX,
    output reg [1:0] LEDR);
    
    wire rst = ~RESET_N;
    wire valid, start;
    wire [7:0] r, g, b;

    wire v1, v2, v3, done;
    wire [7:0] gray;
    wire pix_bin, pix_er;
    wire [13:0] area;
    wire [15:0] perimeter;
    wire [7:0] w, h;
    wire result_valid, is_bean;

    // 1. Recepción UART y armado de píxeles RGB
    image #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) u_img (
        .CLOCK_50(CLOCK_50), .RESET_N(RESET_N),
        .UART_RX(UART_RX), .UART_TX(UART_TX),
        .valid_o(valid), .start_o(start),
        .R(r), .G(g), .B(b)
    );

    // 2. Escala de grises
    grayscale u_gray (
        .clk(CLOCK_50), .rst(rst), .valid(valid),
        .R(r), .G(g), .B(b), .valid_o(v1), .gray(gray)
    );

    // 3. Binarización
    thresholding u_thr (
        .clk(CLOCK_50), .rst(rst), .valid(v1),
        .gray(gray), .valid_o(v2), .pixel(pix_bin)
    );

    // 4. Erosión / Contorno
    contouring #(.WIDTH(WIDTH)) u_ero (
        .clk(CLOCK_50), .rst(rst), .valid(v2), .pixel(pix_bin),
        .valid_o(v3), .pixel_o(pix_er)
    );

    // 5. Extracción de área, perímetro, ancho y alto
    features #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) u_feat (
        .clk(CLOCK_50), .rst(rst), .start(start), .valid(v3), .pixel(pix_er),
        .done(done), .area(area), .perimeter(perimeter),
        .w(w), .h(h)
    );

    // 6. Clasificación
    classify #(
        .AREA_MIN(AREA_MIN), .AREA_MAX(AREA_MAX),
        .PERIM_MIN(PERIM_MIN), .PERIM_MAX(PERIM_MAX),
        .AR_MIN(AR_MIN), .AR_MAX(AR_MAX)
    ) u_cls (
        .clk(CLOCK_50), .rst(rst), .done(done),
        .area(area), .perimeter(perimeter), .w(w), .h(h),
        .result_valid(result_valid), .is_bean(is_bean)
    );

    // 7. Contador de frijoles y LEDs de estado
    reg [6:0] bean_count; // Cuenta de 0 a 99

    always @(posedge CLOCK_50 or posedge rst) begin
        if (rst) begin
            bean_count <= 7'd0;
            LEDR <= 2'b00;
        end else if (result_valid) begin
            if (is_bean) begin
                LEDR <= 2'b01;
                if (bean_count < 7'd99)
                    bean_count <= bean_count + 7'd1;
            end else begin
                LEDR <= 2'b10;
            end
        end
    end

    // Decodificador BCD a 7 segmentos (ánodo común DE10-Lite)
    wire [3:0] units = bean_count % 10;
    wire [3:0] tens  = bean_count / 10;

    assign HEX0 = seg7(units);
    assign HEX1 = seg7(tens);

    function [6:0] seg7(input [3:0] d);
        case (d)
            4'd0: seg7 = 7'b1000000;
            4'd1: seg7 = 7'b1111001;
            4'd2: seg7 = 7'b0100100;
            4'd3: seg7 = 7'b0110000;
            4'd4: seg7 = 7'b0011001;
            4'd5: seg7 = 7'b0010010;
            4'd6: seg7 = 7'b0000010;
            4'd7: seg7 = 7'b1111000;
            4'd8: seg7 = 7'b0000000;
            4'd9: seg7 = 7'b0010000;
            default: seg7 = 7'b1111111;
        endcase
    endfunction

endmodule


