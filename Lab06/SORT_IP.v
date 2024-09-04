//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright System Integration and Silicon Implementation Laboratory
//    All Right Reserved
//		Date		: 2023/10
//		Version		: v1.0
//   	File Name   : SORT_IP.v
//   	Module Name : SORT_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module SORT_IP #(parameter IP_WIDTH = 8) (
           // Input signals
           IN_character, IN_weight,
           // Output signals
           OUT_character, OUT_weight
       );

//---------------------------------------------------------------------
//   Input & Output Declaration
//---------------------------------------------------------------------
input      [IP_WIDTH*4-1:0] IN_character;
input      [IP_WIDTH*5-1:0] IN_weight;

output reg [IP_WIDTH*4-1:0] OUT_character;
output reg [IP_WIDTH*5-1:0] OUT_weight;
//---------------------------------------------------------------------
//   LOGIC DECLARATION
//---------------------------------------------------------------------
wire       lv         [0:IP_WIDTH-1][0:IP_WIDTH-1];
reg  [2:0] addr       [0:IP_WIDTH-1];
reg  [3:0] out_result [0:IP_WIDTH-1];               // each IN_character is 4 bits
reg  [4:0] out_weight [0:IP_WIDTH-1];               // each IN_weight    is 5 bits

integer a;
genvar  i, j;

//---------------------------------------------------------------------
//   Design
//---------------------------------------------------------------------

// Counting Sort
// Refer to Lab01......
generate
    for(i=0;i<IP_WIDTH;i=i+1)
    begin
        for(j=0;j<IP_WIDTH;j=j+1)
        begin
            if(j < i) assign lv[i][j] = ~lv[j][i];
            if(j > i) assign lv[i][j] = (IN_weight[5*i+4:5*i] > IN_weight[5*j+4:5*j])? 1'b1 : 1'b0;
        end
    end
endgenerate

always @(*) 
begin
    case (IP_WIDTH)
        2:
        begin
            addr[0] = lv[0][1];
            addr[1] = lv[1][0];
        end
        3:
        begin
            addr[0] = lv[0][1] + lv[0][2];
            addr[1] = lv[1][0] + lv[1][2];
            addr[2] = lv[2][0] + lv[2][1];
        end
        4:
        begin
            addr[0] = lv[0][1] + lv[0][2] + lv[0][3];
            addr[1] = lv[1][0] + lv[1][2] + lv[1][3];
            addr[2] = lv[2][0] + lv[2][1] + lv[2][3];
            addr[3] = lv[3][0] + lv[3][1] + lv[3][2];
        end
        5:
        begin
            addr[0] = lv[0][1] + lv[0][2] + lv[0][3] + lv[0][4];
            addr[1] = lv[1][0] + lv[1][2] + lv[1][3] + lv[1][4];
            addr[2] = lv[2][0] + lv[2][1] + lv[2][3] + lv[2][4];
            addr[3] = lv[3][0] + lv[3][1] + lv[3][2] + lv[3][4];
            addr[4] = lv[4][0] + lv[4][1] + lv[4][2] + lv[4][3];
        end
        6:
        begin
            addr[0] = lv[0][1] + lv[0][2] + lv[0][3] + lv[0][4] + lv[0][5];
            addr[1] = lv[1][0] + lv[1][2] + lv[1][3] + lv[1][4] + lv[1][5];
            addr[2] = lv[2][0] + lv[2][1] + lv[2][3] + lv[2][4] + lv[2][5];
            addr[3] = lv[3][0] + lv[3][1] + lv[3][2] + lv[3][4] + lv[3][5];
            addr[4] = lv[4][0] + lv[4][1] + lv[4][2] + lv[4][3] + lv[4][5];
            addr[5] = lv[5][0] + lv[5][1] + lv[5][2] + lv[5][3] + lv[5][4];
        end
        7:
        begin
            addr[0] = lv[0][1] + lv[0][2] + lv[0][3] + lv[0][4] + lv[0][5] + lv[0][6];
            addr[1] = lv[1][0] + lv[1][2] + lv[1][3] + lv[1][4] + lv[1][5] + lv[1][6];
            addr[2] = lv[2][0] + lv[2][1] + lv[2][3] + lv[2][4] + lv[2][5] + lv[2][6];
            addr[3] = lv[3][0] + lv[3][1] + lv[3][2] + lv[3][4] + lv[3][5] + lv[3][6];
            addr[4] = lv[4][0] + lv[4][1] + lv[4][2] + lv[4][3] + lv[4][5] + lv[4][6];
            addr[5] = lv[5][0] + lv[5][1] + lv[5][2] + lv[5][3] + lv[5][4] + lv[5][6];   
            addr[6] = lv[6][0] + lv[6][1] + lv[6][2] + lv[6][3] + lv[6][4] + lv[6][5];   
        end
        8:
        begin
            addr[0] = lv[0][1] + lv[0][2] + lv[0][3] + lv[0][4] + lv[0][5] + lv[0][6] + lv[0][7];
            addr[1] = lv[1][0] + lv[1][2] + lv[1][3] + lv[1][4] + lv[1][5] + lv[1][6] + lv[1][7];
            addr[2] = lv[2][0] + lv[2][1] + lv[2][3] + lv[2][4] + lv[2][5] + lv[2][6] + lv[2][7];
            addr[3] = lv[3][0] + lv[3][1] + lv[3][2] + lv[3][4] + lv[3][5] + lv[3][6] + lv[3][7];
            addr[4] = lv[4][0] + lv[4][1] + lv[4][2] + lv[4][3] + lv[4][5] + lv[4][6] + lv[4][7];
            addr[5] = lv[5][0] + lv[5][1] + lv[5][2] + lv[5][3] + lv[5][4] + lv[5][6] + lv[5][7];   
            addr[6] = lv[6][0] + lv[6][1] + lv[6][2] + lv[6][3] + lv[6][4] + lv[6][5] + lv[6][7]; 
            addr[7] = lv[7][0] + lv[7][1] + lv[7][2] + lv[7][3] + lv[7][4] + lv[7][5] + lv[7][6]; 
        end 
        default: 
        begin
            for(a=0;a<IP_WIDTH;a=a+1)
                addr[a] = 0;
        end
    endcase
end

always @(*) 
begin
    case (IP_WIDTH)
        2:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
        end
        3:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
        end
        4:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[3] = 0;            
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
            out_result[addr[3]] = IN_character[15:12];
        end
        5:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[3] = 0;            
            out_result[4] = 0;        
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
            out_result[addr[3]] = IN_character[15:12];
            out_result[addr[4]] = IN_character[19:16];
        end
        6:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[3] = 0;            
            out_result[4] = 0;        
            out_result[5] = 0;        
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
            out_result[addr[3]] = IN_character[15:12];
            out_result[addr[4]] = IN_character[19:16];
            out_result[addr[5]] = IN_character[23:20];
        end
        7:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[3] = 0;            
            out_result[4] = 0;        
            out_result[5] = 0;        
            out_result[6] = 0;        
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
            out_result[addr[3]] = IN_character[15:12];
            out_result[addr[4]] = IN_character[19:16];
            out_result[addr[5]] = IN_character[23:20]; 
            out_result[addr[6]] = IN_character[27:24]; 
        end
        8:
        begin
            out_result[0] = 0;
            out_result[1] = 0;            
            out_result[2] = 0;            
            out_result[3] = 0;            
            out_result[4] = 0;        
            out_result[5] = 0;        
            out_result[6] = 0;        
            out_result[7] = 0;        
            out_result[addr[0]] = IN_character[3:0];
            out_result[addr[1]] = IN_character[7:4];
            out_result[addr[2]] = IN_character[11:8];
            out_result[addr[3]] = IN_character[15:12];
            out_result[addr[4]] = IN_character[19:16];
            out_result[addr[5]] = IN_character[23:20]; 
            out_result[addr[6]] = IN_character[27:24]; 
            out_result[addr[7]] = IN_character[31:28]; 
        end 
        default: 
        begin
            for(a=0;a<IP_WIDTH;a=a+1)
                out_result[a] = 0;
        end
    endcase
end

generate
    for(i=0;i<IP_WIDTH;i=i+1)
        always@(*) OUT_character[4*i+3:4*i] = out_result[i];
endgenerate

always @(*) 
begin
    out_weight[0]       = 0;
    out_weight[1]       = 0;
    out_weight[2]       = 0;
    out_weight[3]       = 0;
    out_weight[4]       = 0;
    out_weight[5]       = 0;
    out_weight[6]       = 0;
    out_weight[7]       = 0;
    out_weight[addr[0]] = IN_weight[4:0];
    out_weight[addr[1]] = IN_weight[9:5];
    out_weight[addr[2]] = IN_weight[14:10];
    out_weight[addr[3]] = IN_weight[19:15];
    out_weight[addr[4]] = IN_weight[24:20];
    out_weight[addr[5]] = IN_weight[29:25]; 
    out_weight[addr[6]] = IN_weight[34:30]; 
    out_weight[addr[7]] = IN_weight[39:35];
end

always @(*) 
begin
    case (IP_WIDTH)
        8:       OUT_weight = {out_weight[7], out_weight[6], out_weight[5], out_weight[4], out_weight[3], out_weight[2], out_weight[1], out_weight[0]};
        default: OUT_weight = 0;
    endcase
end

endmodule
