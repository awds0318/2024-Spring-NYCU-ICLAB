`define CYCLE_TIME 20

module PATTERN #(parameter IP_WIDTH = 8)(
    //Output Port
    IN_character,
	IN_weight,
    //Input Port
	OUT_character
);
// ========================================
// Input & Output
// ========================================
output reg [IP_WIDTH*4-1:0] IN_character;
output reg [IP_WIDTH*5-1:0] IN_weight;

input [IP_WIDTH*4-1:0] OUT_character;

// ========================================
// Parameter
// ========================================
real CYCLE = `CYCLE_TIME;
parameter PARRTRN_NUM = 30000;
integer i_pat, j_ip, k_ip;
integer t;
reg [3:0] character [0:IP_WIDTH-1];
reg [4:0] weight [0:IP_WIDTH-1];
reg [3:0] character_temp;
reg [4:0] weight_temp;

// String control
// Should use %0s
reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

//================================================================
// design
//================================================================

initial begin
    i_pat = 0;
    IN_character = 0;
    IN_weight = 0;

    for(i_pat = 0; i_pat < PARRTRN_NUM; i_pat = i_pat + 1) begin
        // input_task
        // intialize
        IN_character = 0;
        IN_weight = 0;
        // $display("PATTERN  No.%d", i_pat);

        for(j_ip = 0; j_ip < IP_WIDTH; j_ip = j_ip + 1) begin
            IN_character = IN_character << 4;
            IN_character = IN_character + (IP_WIDTH - j_ip - 1);
            // $display("IN_character[%1d] = %1d", IP_WIDTH - j_ip - 1, IP_WIDTH - j_ip - 1);
            character[j_ip] = IP_WIDTH - j_ip - 1;
        end
        
        for(k_ip = 0; k_ip < IP_WIDTH; k_ip = k_ip + 1) begin
            IN_weight = IN_weight << 5;
            t = $urandom_range(0, 31);
            IN_weight = IN_weight + t;
            // $display("IN_weight[%1d] = %1d", IP_WIDTH - k_ip - 1, t);
            weight[k_ip] = t;
        end

        // $display("--------------------");

        // bubble sort
        for(j_ip = 0; j_ip < IP_WIDTH - 1; j_ip = j_ip + 1) begin
            // Last i elements are already in place, so we don't need to check them
            for(k_ip = 0; k_ip < IP_WIDTH - j_ip - 1; k_ip = k_ip + 1) begin
                if (weight[k_ip] < weight[k_ip + 1]) begin
                    // Swap weight[k_ip] and weight[k_ip + 1]
                    weight_temp = weight[k_ip];
                    weight[k_ip] = weight[k_ip + 1];
                    weight[k_ip + 1] = weight_temp;

                    // Swap character[k_ip] and character[k_ip + 1]
                    character_temp = character[k_ip];
                    character[k_ip] = character[k_ip + 1];
                    character[k_ip + 1] = character_temp;
                end
            end
        end

        #CYCLE;

        // check_ans_task
        if(IP_WIDTH === 8) begin
            if(OUT_character[31:28] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[31:28] = %1d, it should be %1d", OUT_character[31:28], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[27:24] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[27:24] = %1d, it should be %1d", OUT_character[27:24], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[23:20] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[23:20] = %1d, it should be %1d", OUT_character[23:20], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[19:16] !== character[3]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[19:16] = %1d, it should be %1d", OUT_character[19:16], character[3]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[15:12] !== character[4]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[15:12] = %1d, it should be %1d", OUT_character[15:12], character[4]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[11:8] !== character[5]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[5]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[6]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[6]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[7]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[7]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 7) begin
            if(OUT_character[27:24] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[27:24] = %1d, it should be %1d", OUT_character[27:24], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[23:20] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[23:20] = %1d, it should be %1d", OUT_character[23:20], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[19:16] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[19:16] = %1d, it should be %1d", OUT_character[19:16], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[15:12] !== character[3]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[15:12] = %1d, it should be %1d", OUT_character[15:12], character[3]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[11:8] !== character[4]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[4]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[5]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[5]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[6]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[6]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 6) begin
            if(OUT_character[23:20] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[23:20] = %1d, it should be %1d", OUT_character[23:20], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[19:16] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[19:16] = %1d, it should be %1d", OUT_character[19:16], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[15:12] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[15:12] = %1d, it should be %1d", OUT_character[15:12], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[11:8] !== character[3]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[3]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[4]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[4]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[5]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[5]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 5) begin
            if(OUT_character[19:16] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[19:16] = %1d, it should be %1d", OUT_character[19:16], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[15:12] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[15:12] = %1d, it should be %1d", OUT_character[15:12], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[11:8] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[3]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[3]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[4]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[4]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 4) begin
            if(OUT_character[15:12] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[15:12] = %1d, it should be %1d", OUT_character[15:12], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[11:8] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[3]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[3]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 3) begin
            if(OUT_character[11:8] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[11:8] = %1d, it should be %1d", OUT_character[11:8], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[7:4] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[2]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[2]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else if(IP_WIDTH === 2) begin

            if(OUT_character[7:4] !== character[0]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[7:4] = %1d, it should be %1d", OUT_character[7:4], character[0]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end

            if(OUT_character[3:0] !== character[1]) begin
                $display("==========================================================================");
                $display("    Out is not correct at %-12d ps ", $time*1000);
                $display("OUT_character[3:0] = %1d, it should be %1d", OUT_character[3:0], character[1]);
                $display("==========================================================================");
                #CYCLE;
                $finish;
            end
        end else begin
            $display("==========================================================================");
            $display("    IP_WIDTH is not correct at %-12d ps ", $time*1000);
            $display("==========================================================================");
            #CYCLE;
            $finish;
        end
    
        $display("%0sPASS PATTERN NO.%d%0s",txt_blue_prefix, i_pat, reset_color);
    end


    $display("\033[1;35m For IP_WIDTH =  %1d \033[1;0m", IP_WIDTH);
    $display("\033[1;35m Pass All PATTERN, Congratulation! \033[1;0m");
end

endmodule