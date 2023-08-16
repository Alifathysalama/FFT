module FFT_DIT_Radix2 #(
    parameter WIDTH = 4 
)(
    input signed [WIDTH-1:0] in_real,
    input signed [WIDTH-1:0] in_image,
    input clk,
    input in_EN,
    input start,
    input out_EN,
    input [1:0] Stage,
    output reg signed [37:0] out_real,
    output reg signed [37:0] out_image,
    output reg [1:0] Done,
    output reg out_flag,
    output reg overflow
);

    // Registers for each stage, more area and power, but it has a powerful impact on performance
    reg signed [WIDTH-1:0] A_real [15:0]; // First stage real output
    reg signed [WIDTH-1:0] A_image [15:0]; // First stage image output
    reg signed [WIDTH+1:0] B_real [15:0]; // Second stage real output
    reg signed [WIDTH+1:0] B_image [15:0]; // Second stage image output
    reg signed [21:0] C_real [15:0]; // Third stage real output
    reg signed [21:0] C_image [15:0]; // Third stage image output
    reg signed [37:0] X_real [15:0]; // Fourth stage real output
    reg signed [37:0] X_image [15:0]; // Fourth stage image output

    // Twiddle factors. No need for a (first stage or second stage) memory 
    reg signed [15:0] tw_3 [1:0]; // Third stage output
    reg signed [15:0] tw_4 [5:0]; // Fourth stage output

    // Necessary registers
    reg [3:0] out_counter, counter;

    // Initializing memory 
    initial begin
        $readmemh("third_stage_twiddle_factor.data", tw_3);
        $readmemh("forth_stage_twiddle_factor.data", tw_4);
        out_counter = 0;
        out_flag = 0;
    end

    // Waiting for input to enter about 16 clock cycles 
    always @(posedge clk) begin
        if (start) begin
            counter <= 0;
            overflow <= 0;
        end
        if (in_EN & overflow == 0) begin
            A_real[0 + counter] <= in_real;
            A_image[0 + counter] <= in_image;
            {overflow, counter} <= counter + 1;
        end
    end
    integer i,idx1,idx2 ;

    // Operation of the stages 
    always @(posedge clk) begin
        if (!in_EN) begin
            case (Stage)
                2'b00: begin
                    // In the first stage, all is real; no image multiplication
                    for (i = 0; i < 16; i = i + 2) begin
                        case (i)
                            0: begin
                                idx1 = 0;
                                idx2 = 8;
                            end
                            2: begin
                                idx1 = 4;
                                idx2 = 12;
                            end
                            4: begin
                                idx1 = 2;
                                idx2 = 10;
                            end
                            6: begin
                                idx1 = 6;
                                idx2 = 14;
                            end
                            8: begin
                                idx1 = 1;
                                idx2 = 9;
                            end
                            10: begin
                                idx1 = 5;
                                idx2 = 13;
                            end
                            12: begin
                                idx1 = 3;
                                idx2 = 11;
                            end
                            14: begin
                                idx1 = 7;
                                idx2 = 15;
                            end
                        endcase

                        // Real part
                        A_real[idx1] <= A_real[idx1] + A_real[idx2];
                        A_real[idx2] <= A_real[idx1] - A_real[idx2];

                        // Image part
                        A_image[idx1] <= A_image[idx1] + A_image[idx2];
                        A_image[idx2] <= A_image[idx1] - A_image[idx2];
                    end
                    Done <= 2'b00;
                end
                2'b01: begin
                    // For the second stage, all second inputs are multiplied with -j, so it's easy to calculate
                    for ( i = 0; i < 16; i = i + 2) begin
                        // Real part
                        B_real[i] <= A_real[i] + A_real[i + 1];
                        B_real[i + 1] <= A_real[i] - A_real[i + 1] - 2 * A_image[i + 1];
                        // Image part
                        B_image[i] <= A_image[i] + A_image[i + 1];
                        B_image[i + 1] <= A_image[i] - A_image[i + 1] + 2 * A_real[i + 1];
                    end
                    Done <= 2'b01;
                end
                2'b10: begin
                    // In the third stage, we will use the general formula when we multiply two complex numbers:
                    // (a + bj)(c + dj) = (ac - bd) + j(ad + bc)
                    for ( i = 0; i < 16; i = i + 4) begin
                        // Real part
                        C_real[i] <= B_real[i] + B_real[i + 2];
                        C_real[i + 2] <= B_real[i] - B_real[i + 2];
                        C_real[i + 1] <= B_real[i + 1] + tw_3[0] * B_real[i + 3] - tw_3[1] * B_image[i + 3];
                        C_real[i + 3] <= B_real[i + 1] - tw_3[0] * B_real[i + 3] + tw_3[1] * B_image[i + 3];
                        // Image part
                        C_image[i] <= B_image[i] + B_image[i + 2];
                        C_image[i + 2] <= B_image[i] - B_image[i + 2];
                        C_image[i + 1] <= B_image[i + 1] + tw_3[0] * B_image[i + 3] + tw_3[1] * B_real[i + 3];
                        C_image[i + 3] <= B_image[i + 1] - tw_3[0] * B_image[i + 3] - tw_3[1] * B_real[i + 3];
                    end
                    Done <= 2'b10;
                end
                2'b11: begin
                    // Same as stage 3 in handling complex multiplication
                    for ( i = 0; i < 16; i = i + 8) begin
                        // Real part
                        X_real[i] <= C_real[i] + C_real[i + 4];
                        X_real[i + 4] <= C_real[i] - C_real[i + 4];
                        X_real[i + 1] <= C_real[i + 1] + tw_4[0] * C_real[i + 5] - tw_4[5] * C_image[i + 5];
                        X_real[i + 5] <= C_real[i + 1] - tw_4[0] * C_real[i + 5] + tw_4[5] * C_image[i + 5];
                        X_real[i + 2] <= C_real[i + 2] + tw_4[1] * C_real[i + 6] - tw_4[4] * C_image[i + 6];
                        X_real[i + 6] <= C_real[i + 2] - tw_4[1] * C_real[i + 6] + tw_4[4] * C_image[i + 6];
                        X_real[i + 3] <= C_real[i + 3] + tw_4[2] * C_real[i + 7] - tw_4[3] * C_image[i + 7];
                        X_real[i + 7] <= C_real[i + 3] - tw_4[2] * C_real[i + 7] + tw_4[3] * C_image[i + 7];
                        // Image part
                        X_image[i] <= C_image[i] + C_image[i + 4];
                        X_image[i + 4] <= C_image[i] - C_image[i + 4];
                        X_image[i + 1] <= C_image[i + 1] + tw_4[0] * C_image[i + 5] + tw_4[5] * C_real[i + 5];
                        X_image[i + 5] <= C_image[i + 1] - tw_4[0] * C_image[i + 5] - tw_4[5] * C_real[i + 5];
                        X_image[i + 2] <= C_image[i + 2] + tw_4[1] * C_image[i + 6] + tw_4[4] * C_real[i + 6];
                        X_image[i + 6] <= C_image[i + 2] - tw_4[1] * C_image[i + 6] - tw_4[4] * C_real[i + 6];
                        X_image[i + 3] <= C_image[i + 3] + tw_4[2] * C_image[i + 7] + tw_4[3] * C_real[i + 7];
                        X_image[i + 7] <= C_image[i + 3] - tw_4[2] * C_image[i + 7] - tw_4[3] * C_real[i + 7];
                    end
                    Done <= 2'b11;
                end
                default: begin
                    Done <= 2'b00; // Reset to 2'b00 if no valid stage selected
                end
            endcase
        end
    end

    // Output 
    always @(posedge clk) begin
        if (out_EN) begin
            out_real <= X_real[out_counter];
            out_image <= X_image[out_counter];
            out_counter <= out_counter + 1;
            if (out_counter == 4'b1111) begin
                out_flag <= 1;
            end
        end
    end
endmodule
