module classify #(
    parameter AREA_MIN     = 335,
    parameter AREA_MAX     = 471,
    parameter PERIM_MIN    = 71,
    parameter PERIM_MAX    = 90,
    parameter AR_FRAC      = 4, 
    parameter AR_MIN_X1000 = 1200,   // 1.200
    parameter AR_MAX_X1000 = 2100,   // 2.100
    parameter CX_MIN = 24, 
	 parameter CX_MAX = 104,
    parameter CY_MIN = 24, 
	 parameter CY_MAX = 104
)(
    input wire clk,
    input wire rst,
    input wire done,
    input wire [14:0] area,
    input wire [16:0] perimeter,
    input wire [7:0] w,
    input wire [7:0] h,
    input wire [7:0] cx,
    input wire [7:0] cy,
    output reg result_valid,
    output reg is_bean
);
    localparam AR_MIN = (AR_MIN_X1000 * (1 << AR_FRAC) + 500) / 1000;
    localparam AR_MAX = (AR_MAX_X1000 * (1 << AR_FRAC) + 500) / 1000;

    wire [7:0]  lng = (w >= h) ? w : h;
    wire [7:0]  sht = (w >= h) ? h : w;
    wire [15:0] l16 = {8'd0, lng} << AR_FRAC;
    wire [15:0] lo  = AR_MIN * sht;
    wire [15:0] hi  = AR_MAX * sht;

    wire ok_area = (area >= AREA_MIN) && (area <= AREA_MAX);
    wire ok_per  = (perimeter >= PERIM_MIN) && (perimeter <= PERIM_MAX);
    wire ok_ar   = (sht != 8'd0) && (l16 >= lo) && (l16 <= hi);
    wire ok_cen  = (cx >= CX_MIN) && (cx <= CX_MAX) &&
                   (cy >= CY_MIN) && (cy <= CY_MAX);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_valid <= 1'b0;
            is_bean      <= 1'b0;
        end else begin
            result_valid <= done;
            if (done)
                is_bean <= ok_area && ok_per && ok_ar; //por el momento sin centroide
        end
    end
endmodule
