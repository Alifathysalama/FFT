module FFT #(
    parameter WIDTH = 4 
)(
    input reset,
    input clk,
    input signed [WIDTH-1:0] in_real,
    input signed [WIDTH-1:0] in_image,
    output FFT_Done,
    output signed [37:0] out_real,
    output signed [37:0] out_image
);
    //------------------------------
    wire start,in_EN,out_EN,out_flag,overflow;
    wire [3:0] counter;
    wire [1:0] Done,Stage;
    //-----------------------------

    FFT_DIT_Radix2 FFT_DIT2_Radix2(
        .clk(clk),
        .in_EN(in_EN),
        .start(start),
        .out_EN(out_EN),
        .in_real(in_real),
        .in_image(in_image),
        .out_real(out_real),
        .out_image(out_image),
        .out_flag(out_flag),
        .Done(Done),
        .Stage(Stage),
        .overflow(overflow)
    );

    CU CU_1(
        .reset(reset),
        .overflow(overflow),
        .out_flag(out_flag),
        .Done(Done),
        .Stage(Stage),
        .start(start),
        .in_EN(in_EN),
        .out_EN(out_EN),
        .FFT_Done(FFT_Done)
    );

endmodule