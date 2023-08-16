module CU (
    input reset,
    input overflow,
    input out_flag,
    input  [1:0] Done,
    output reg [1:0] Stage,
    output reg start,
    output reg in_EN,
    output out_EN,
    output FFT_Done
);

  reg flag ;

    // input part handling 
    always @(*) begin
      if (reset) begin
            start = 1;
            flag = 0;
        end
        else begin
            start = 0 ;
            in_EN = 1 ;
            if (overflow) begin
                in_EN = 0 ;
                Stage  = 2'b00;
            end
        end
    end
    always @(Done) begin
        case (Done)
              2'b00: begin
                Stage = 2'b01;
                flag = 0;
              end
              2'b01: begin
                Stage = 2'b10;
                flag = 0;
              end
              2'b10 : begin
                Stage = 2'b11;
                flag = 0;
              end
              2'b11 : begin
                flag = 1 ;
              end
              default: begin
                Stage = 2'b00;
                flag = 0 ;
              end
        endcase
      end
    assign out_EN = (flag == 1 & out_flag == 0)? 1 : 0 ;
    assign FFT_Done = (out_flag)? 1 : 0;

endmodule