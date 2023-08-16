module FFT_tb();

    reg reset;
    reg [3:0] in_real_tb,in_image_tb;
    wire FFT_Done;
    wire [37:0] out_real_tb,out_image_tb;
    // -------------------------------
    parameter clk_period =  20; 

    reg  clk_tb = 0 ;
    always #(clk_period/2) clk_tb = ~clk_tb; 

    reg  [3:0] mem_real [15:0];
    reg  [3:0] mem_image [15:0];
    //-----------------------------
    initial begin
        $readmemh("input_real.data",mem_real);
        $readmemh("input_image.data",mem_image);
    end
    
    integer i ;

    initial begin
        reset = 1 ;
        #clk_period;
        reset = 0;
        for (i =0  ; i < 16 ;i=i+1 ) begin
            in_image_tb = mem_image[i];
            in_real_tb = mem_real[i];
            @(posedge clk_tb);
        end
        if(FFT_Done) begin
          $stop;
        end
    end

    FFT FFT_1(
    .reset(reset),
    .clk(clk_tb),
    .in_real(in_real_tb),
    .in_image(in_image_tb),
    .FFT_Done(FFT_Done),
    .out_real(out_real_tb),
    .out_image(out_image_tb)
    );

endmodule
