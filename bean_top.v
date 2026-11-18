module bean_top #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128,
    parameter bits = 8,
    parameter BRIGHT = 1,
    parameter AREA_MIN = 400,
    parameter AREA_MAX = 2500,
    parameter PERIM_MIN = 70,
    parameter PERIM_MAX = 220,
    parameter AR_MIN = 20,
    parameter AR_MAX = 40)(
    input wire clk,       
    input wire rst,
    input wire valid,
    input wire start,    
    input wire [bits-1:0] r,
    input wire [bits-1:0] g,
    input wire [bits-1:0] b,
    input wire [bits-1:0] th,
    output wire is_bean);	   
	
    wire v1, v2, v3, done;
    wire [bits-1:0] gray;
    wire pix_bin, pix_er;
    wire [13:0] area;
    wire [15:0] perimeter;
    wire [7:0]  w, h;
    wire        result_valid;

    grayscale u_gray (
        .clk(clk), .rst(rst), .valid(valid),
        .R(r), .G(g), .B(b), .valid_o(v1), .gray(gray));

    thresholding #(.bits(bits), .BRIGHT(BRIGHT)) u_thr (
        .clk(clk), .rst(rst), .valid(v1),
        .gray(gray), .th(th), .valid_o(v2), .pixel(pix_bin));

    contouring #(.WIDTH(WIDTH)) u_ero (
        .clk(clk), .rst(rst), .valid(v2), .pixel(pix_bin),
        .valid_o(v3), .pixel_o(pix_er));

    features #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) u_feat (
        .clk(clk), .rst(rst), .start(start), .valid(v3), .pixel(pix_er),
        .done(done), .area(area), .perimeter(perimeter),
        .w(w), .h(h));

    classify #(
        .AREA_MIN(AREA_MIN), .AREA_MAX(AREA_MAX),
        .PERIM_MIN(PERIM_MIN), .PERIM_MAX(PERIM_MAX),
        .AR_MIN(AR_MIN), .AR_MAX(AR_MAX)) u_cls (
        .clk(clk), .rst(rst), .done(done),
        .area(area), .perimeter(perimeter), .w(w), .h(h),
        .result_valid(result_valid), .is_bean(is_bean));

endmodule

