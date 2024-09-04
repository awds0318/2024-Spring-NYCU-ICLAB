//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Fall
//   Lab05 Exercise		: CAD
//   Author     		: YEH SHUN LIANG (sicajc.st12@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : V1.0 (Release Date: 2023-09)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`define CYCLE_TIME      20.0

module PATTERN(
           //Output Port
           clk,
           rst_n,
           in_valid,
           in_valid2,
           mode,
           matrix,
           matrix_idx,
           matrix_size,
           //Input Port
           out_valid,
           out_value
       );

//---------------------------------------------------------------------
//   PORT DECLARATION
//---------------------------------------------------------------------
output reg         clk, rst_n, in_valid,in_valid2,mode;
output reg signed[7:0]  matrix;
output reg[1:0]        matrix_size;
output reg[3:0]    matrix_idx;
input              out_valid;
input              out_value;

//---------------------------------------------------------------------
//   PARAMETER & INTEGER DECLARATION
//---------------------------------------------------------------------

real CYCLE = `CYCLE_TIME;
integer pat_read, ans_read, file;
integer PAT_NUM;
integer total_latency, latency;
integer out_val_clk_times;
integer i_pat,i,j,k;
integer input_matrix_size;
integer idx_count;
integer golden_size;
reg[1:0] input_matrix_size_idx;

//================================================================
// wire & registers
//================================================================
reg [7:0] img_data [0:15][0:1023]; // 32*32x16
reg [7:0] ker_data [0:15][0:24]; // 5x5x16
reg [3:0] index_pair[0:15][0:1];
reg [19:0] ans;

//================================================================
// clock
//================================================================
initial
    clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial
begin
    pat_read = $fopen("../00_TESTBED/input.txt", "r");
    ans_read = $fopen("../00_TESTBED/output.txt", "r");
    reset_signal_task;

    i_pat = 0;
    total_latency = 0;
    idx_count = 0;
    file = $fscanf(pat_read, "%d", PAT_NUM);
    file = $fscanf(ans_read, "%d", PAT_NUM);

    for (i_pat = 1; i_pat <= PAT_NUM; i_pat = i_pat + 1)
    begin
        input_task;
        wait_out_valid_task;
        check_ans_task;

        // Repeatly checks the answer
        for(idx_count = 1; idx_count < 16; idx_count = idx_count + 1)
        begin
            give_idx_task;
            wait_out_valid_task;
            check_ans_task;
        end

        total_latency = total_latency + latency;
        $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d,\033[m",i_pat , latency);
    end
    $fclose(pat_read);

    YOU_PASS_task;
end

initial
begin
    while(1)
    begin
        if((out_valid === 0) && (out_valid !== 0))
        begin
            $display("***********************************************************************");
            $display("*  Error                                                              *");
            $display("*  The out_data should be reset when out_valid is low.                *");
            $display("***********************************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end
        if((in_valid === 1) && (out_valid === 1))
        begin
            $display("***********************************************************************");
            $display("*  Error                                                              *");
            $display("*  The out_valid cannot overlap with in_valid.                        *");
            $display("***********************************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
end

//================================================================
// task
//================================================================
task reset_signal_task;
    begin
        rst_n    = 1;
        force clk= 0;
        #(0.5 * CYCLE);
        rst_n = 0;
        in_valid = 1'b0;
        in_valid2 = 1'b0;
        mode = 1'bx;
        matrix = 1'bx;
        matrix_idx = 1'bx;
        matrix_size = 1'bx;
        #(10 * CYCLE);
        if( (out_valid !== 0) || (out_value !== 0) )
        begin
            $display("***********************************************************************");
            $display("*  Error                                                              *");
            $display("*  Output signal should reset after initial RESET                     *");
            $display("***********************************************************************");
            $finish;
        end
        #(CYCLE);
        rst_n=1;
        #(CYCLE);
        release clk;
    end
endtask
reg mode_list[0:15];
task input_task;
    begin
        // a = $fscanf(pat_read, "%d", Opt_reg);
        // for (i=0;i<48;i=i+1)
        //     a = $fscanf(pat_read, "%h", Img_reg[i]);
        // for (i=0;i<27;i=i+1)
        //     a = $fscanf(pat_read, "%h", Kernel_reg[i]);
        // for (i=0;i<4;i=i+1)
        //     a = $fscanf(pat_read, "%h", Weight_reg[i]);

        // repeat(($urandom(SEED) % 3 + 2)) @(negedge clk); // random delay for 2 ~ 4 cycle
        // Read in the matrix size
        file = $fscanf(pat_read, "%d",input_matrix_size_idx);

        case(input_matrix_size_idx)
            'd0:
                input_matrix_size = 8;
            'd1:
                input_matrix_size = 16;
            'd2:
                input_matrix_size = 32;
        endcase

        // read in a total of 16 images
        for(i = 0; i<16 ; i=i+1)
            for(j = 0; j < input_matrix_size * input_matrix_size; j=j+1)
                file = $fscanf(pat_read, "%b", img_data[i][j]);

        // Read in 16 kernals
        for(i = 0; i<16 ; i=i+1)
            for(j = 0; j < 25; j=j+1)
                file  = $fscanf(pat_read, "%b", ker_data[i][j]);

        // Set pattern signal
        repeat(3)@(negedge clk);

        in_valid = 1'b1;
        matrix_size = input_matrix_size_idx;

        // Sends matrix
        for(i = 0; i < 16; i=i+1)
            for(j = 0; j < input_matrix_size * input_matrix_size; j=j+1)
            begin
                matrix = img_data[i][j];
                @(negedge clk);
                matrix_size = 'bx;
            end

        // Sends kernal
        for(i = 0; i < 16; i=i+1)
            for(j = 0; j < 25; j=j+1)
            begin
                matrix = ker_data[i][j];
                @(negedge clk);
            end

        // Clear in_valid and matrix
        in_valid = 1'b0;
        matrix   = 'bx;

        // Delays
        repeat(2)@(negedge clk);

        // reads mode in

        in_valid2 = 1'b1;

        // Reads the index into a matrix
        for(i = 0; i < 16; i = i+1)
        begin
            file = $fscanf(pat_read,"%h",index_pair[i][0]);
            file = $fscanf(pat_read,"%h",index_pair[i][1]);
            file = $fscanf(pat_read,"%h",mode_list[i]);
        end

        matrix_idx = index_pair[0][0];
        mode       = mode_list[0];
        @(negedge clk);
        mode       = 'bx;
        matrix_idx = index_pair[0][1];
        @(negedge clk);

        matrix_idx = 'bx;
        in_valid2  = 1'b0;
    end
endtask

task wait_out_valid_task;
    begin
        latency = -1;
        while(out_valid !== 1)
        begin
            latency = latency + 1;
            if(latency >= 100000)
            begin
                $display("***********************************************************************");
                $display("*  Error                                                              *");
                $display("*  The execution latency are over  100000 cycles.                      *");
                $display("***********************************************************************");
                repeat(2)@(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
        total_latency = total_latency + latency;
    end
endtask
reg[19:0] golden_reversed_byte;
reg[19:0] out_value_seq;
reg[9:0] temp;

task check_ans_task;
    begin
        case (mode_list[0])
            0:
                temp = (input_matrix_size - 4) / 2;
            1:
                temp = input_matrix_size - 2;
            default:
                temp = 0;
        endcase

        while(out_valid == 1)
        begin
            for(k=0;k<(temp*temp);k=k+1)
            begin
                file = $fscanf(ans_read,"%h",golden_reversed_byte);
                // $display("%b",golden_reversed_byte);
                // $display("NO : %d",k);
                out_value_seq = 'bx;

                for(j=0 ; j < 20; j=j+1)
                begin
                    // $display("golden j: %d",j);

                    // out_value_seq[i] = out_value;
                    if(out_valid !== 1)
                    begin
                        $display("***********************************************************************");
                        $display("*  Error                                                              *");
                        $display("*  Out valid should be 1 when outputing the data                      *");
                        $display("*  Current index of output matrix %d , bit of output matrix %d *",i,j   );
                        $display("***********************************************************************");
                        repeat(2)@(negedge clk);
                        $finish;
                    end

                    // $display("i = %d,j = %d ,out_value = %d, golden = %d",i,j,out_value,golden_reversed_byte[j]);
                    if(out_value !== golden_reversed_byte[j])
                    begin
                        // $display("your value: %b",out_value);
                        // $display("golden value: %b",golden_reversed_byte[j]);
                        // $display("golden j: %d",j);
                        $display("***********************************************************************");
                        $display("*  Error                                                              *");
                        $display("*  The out_data should be correct when out_valid is high              *");
                        $display("*  Golden       : 0x%5h                    *",golden_reversed_byte);
                        $display("*  Golden       : %5d                    *",golden_reversed_byte);
                        $display("*  Golden       : 0b%20b                   *",golden_reversed_byte);
                        $display("***********************************************************************");
                        repeat(2)@(negedge clk);
                        $finish;
                    end
                    @(negedge clk);
                end
            end
        end
        if(out_valid !== 0  || out_value !== 0)
        begin
            $display("***********************************************************************");
            $display("*  Error                                                              *");
            $display("*  Output signal should reset after outputting the data               *");
            $display("***********************************************************************");
            repeat(2)@(negedge clk);
            $finish;
        end
        repeat(4)@(negedge clk);
    end
endtask

task give_idx_task;
    begin
        in_valid2 = 1'b1;
        mode      = mode_list[idx_count];
        matrix_idx = index_pair[idx_count][0];
        @(negedge clk);
        matrix_idx = index_pair[idx_count][1];
        mode   = 'bx;
        @(negedge clk);
        in_valid2  = 1'b0;
        matrix_idx = 'bx;
    end
endtask


task YOU_PASS_task;
    begin
        $display("***********************************************************************");
        $display("*                           \033[0;32mCongratulations!\033[m                          *");
        $display("*  Your execution cycles = %18d   cycles                *", total_latency);
        $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
        $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
        $display("***********************************************************************");
        $finish;
    end
endtask


endmodule
