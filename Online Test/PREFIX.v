module PREFIX (
           // input port
           clk,
           rst_n,
           in_valid,
           opt,
           in_data,
           // output port
           out_valid,
           out
       );
//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------
input       clk;
input       rst_n;
input       in_valid;
input       opt;
input [4:0] in_data;

output reg               out_valid;
output reg signed [94:0] out;

//---------------------------------------------------------------------
//   PARAMETER DECLARATION
//---------------------------------------------------------------------
localparam IDLE   = 0;
localparam INPUT  = 1;
localparam OPT0   = 2;  // for opt0
localparam SHIFT  = 3;  // for opt0
localparam CAL    = 4;  // for opt1
localparam POP    = 5;  // for opt1
localparam ANS    = 6;
localparam OUTPUT = 7;
reg [2:0] cs ,ns;

//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
integer i, j;

reg               opt_reg;
reg        [4:0]  in_cnt;
reg        [4:0]  opt0_cnt;
reg        [4:0]  cal_cnt;

reg        [4:0]  shift_place [0:18];
reg signed [40:0] in_data_reg [0:18];

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------
always @(posedge clk) in_cnt   <= (in_valid)? in_cnt + 1 : 0;
always @(posedge clk) opt0_cnt <= (cs == OPT0 || cs == SHIFT)? opt0_cnt + 1 : 0;
always @(posedge clk) cal_cnt  <= (cs == CAL)? cal_cnt + 1 : 0;  
always @(posedge clk) opt_reg  <= (in_valid && in_cnt == 0)? opt : opt_reg;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) cs <= IDLE;
    else       cs <= ns;
end

reg [4:0]  R [0:18]; // RPE
reg [4:0]  S [0:18]; // stack
reg [94:0] ans;

wire flag1, flag2;

assign flag1 = ((in_data_reg[18][4:0] == 5'b10000 && (S[0] == 5'b10010 || S[0] == 5'b10011)) || (in_data_reg[18][4:0] == 5'b10001 && (S[0] == 5'b10010 || S[0] == 5'b10011)));
assign flag2 = (                (S[0] == 5'b10000 && (S[1] == 5'b10010 || S[1] == 5'b10011)) ||                 (S[0] == 5'b10001 && (S[1] == 5'b10010 || S[1] == 5'b10011)));

always @(*)
begin
    ns = cs;
    case (cs)
        IDLE:    ns = (in_valid)? INPUT : IDLE;
        INPUT:   ns = (!in_valid)? ((!opt_reg)? OPT0 : CAL) : INPUT;
        OPT0:    ns = SHIFT;
        SHIFT:   ns = (opt0_cnt == 17)? OUTPUT : OPT0;
        CAL:     ns = (in_data_reg[18] == 0)? ANS : ((flag1)? POP : CAL);
        POP:     ns = (in_data_reg[18] == 0)? ANS : ((flag2)? POP : CAL);
        ANS:     ns = OUTPUT;
        OUTPUT:  ns = IDLE;
    endcase
end

always @(posedge clk) 
begin
    if(cs == IDLE)
    begin
        for(i=0;i<19;i=i+1)
        begin
            R[i] <= 0;
            S[i] <= 0;
        end
    end
    else if(cs == CAL)
    begin
        if(in_data_reg[18][4] == 1)
        begin
            if(flag1)
            begin
                R[1:18] <= R[0:17];
                R[0]    <= S[0];
                S[0]    <= in_data_reg[18][4:0]; 
            end
            else
            begin
                S[1:18] <= S[0:17];
                S[0]    <= in_data_reg[18][4:0]; 
            end
        end
        else
        begin
            R[1:18] <= R[0:17];
            R[0]    <= in_data_reg[18][4:0];
        end
    end
    else if(ns == POP)
    begin
        R[1:18] <= R[0:17];
        R[0]    <= S[1];
        S[1:17] <= S[2:18];
        S[18]   <= 0;
    end
    else
    begin
        for(i=0;i<19;i=i+1)
        begin
            R[i] <= R[i];
            S[i] <= S[i];
        end 
    end
end

always @(posedge clk or negedge rst_n) 
begin
    if(!rst_n) ans <= 0;
    else if(ns == ANS)
    begin
        for(j=18;j>=0;j=j-1)
        begin
            if(S[j] == 0)
            begin
                for(i=j;i<19;i=i+1) ans[5*i+:5] <= R[i-j];
                for(i=0;i<j;i=i+1)  ans[5*i+:5] <= S[j-1-i];      
            end
        end
    end
    else ans <= ans;
end

always @(posedge clk)
begin
    if(in_valid) in_data_reg[in_cnt] <= in_data;
    else
    begin
    case (cs)
        IDLE: 
        begin
            for(i=0;i<19;i=i+1)
                in_data_reg[i] <= 0;
        end
        OPT0:
        begin
            case (in_data_reg[shift_place[0]])
                5'b10000: in_data_reg[shift_place[0]] <= in_data_reg[shift_place[0] + 1] + in_data_reg[shift_place[0] + 2];
                5'b10001: in_data_reg[shift_place[0]] <= in_data_reg[shift_place[0] + 1] - in_data_reg[shift_place[0] + 2];
                5'b10010: in_data_reg[shift_place[0]] <= in_data_reg[shift_place[0] + 1] * in_data_reg[shift_place[0] + 2];
                5'b10011: in_data_reg[shift_place[0]] <= in_data_reg[shift_place[0] + 1] / in_data_reg[shift_place[0] + 2];
            endcase 
        end
        SHIFT:
        begin
            in_data_reg[17] <= 0;
            in_data_reg[18] <= 0;

            case (shift_place[0])
                0:  in_data_reg[1 :16] <= in_data_reg[3 :18];
                1:  in_data_reg[2 :16] <= in_data_reg[4 :18];
                2:  in_data_reg[3 :16] <= in_data_reg[5 :18];
                3:  in_data_reg[4 :16] <= in_data_reg[6 :18];
                4:  in_data_reg[5 :16] <= in_data_reg[7 :18];
                5:  in_data_reg[6 :16] <= in_data_reg[8 :18];
                6:  in_data_reg[7 :16] <= in_data_reg[9 :18];
                7:  in_data_reg[8 :16] <= in_data_reg[10:18];
                8:  in_data_reg[9 :16] <= in_data_reg[11:18];
                9:  in_data_reg[10:16] <= in_data_reg[12:18];
                10: in_data_reg[11:16] <= in_data_reg[13:18];
                11: in_data_reg[12:16] <= in_data_reg[14:18];
                12: in_data_reg[13:16] <= in_data_reg[15:18];
                13: in_data_reg[14:16] <= in_data_reg[16:18];
                14: in_data_reg[15:16] <= in_data_reg[17:18];
                15: in_data_reg[16   ] <= in_data_reg[18   ];
            endcase
        end
        CAL:
        begin
            in_data_reg[1:18] <= in_data_reg[0:17];
            in_data_reg[0]    <= 0;    
        end
        default:
        begin
            for(i=0;i<19;i=i+1)
                in_data_reg[i] <= in_data_reg[i];
        end
    endcase
    end
end

always @(posedge clk) 
begin
    if(in_valid && in_data[4] == 1) // be careful using input to judge....
    begin
        shift_place[1:18] <= shift_place[0:17];
        shift_place[0]    <= in_cnt;
    end
    else if(cs == IDLE)
    begin
        for(i=0;i<19;i=i+1)
            shift_place[i] <= 0;    
    end
    else if(cs == SHIFT)
    begin
        shift_place[0:17] <= shift_place[1:18];
        shift_place[18] <= 0;  
    end
    else
    begin
        for(i=0;i<19;i=i+1)
            shift_place[i] <= shift_place[i]; 
    end
end

// ------------------------------------------ Output ------------------------------------------- //
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out <= 0;
    else if(cs == OUTPUT)
    begin
        case (opt_reg)
            0: out <= (in_data_reg[0][40] == 1)? {{54{1'b1}}, in_data_reg[0]} : {{54{1'b0}}, in_data_reg[0]};
            1: out <= ans;
        endcase
    end
    else out <= 0;
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) out_valid <= 0;
    else       out_valid <= (cs == OUTPUT)? 1 : 0;
end

endmodule