//############################################################################
//   2023 ICLAB Fall Course
//   Lab06       : HT
//   Author      : Jyun-wei, Su
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN (HT_TOP)
//   Release version : 2023.10.29
//############################################################################

`ifdef RTL
    `define CYCLE_TIME 5.1
`endif
`ifdef GATE
    `define CYCLE_TIME 5.1
`endif
`define SEED       42
`define PAT_NUM    2000

module PATTERN(
  // Output signals
  clk,
  rst_n,
  in_valid,
  in_weight, 
  out_mode,
  // Input signals
  out_valid, 
  out_code
);

//================================================================
//   PORT DECLARATION          
//================================================================
output reg clk, rst_n, in_valid, out_mode;
output reg [2:0] in_weight;

input out_valid, out_code;

//================================================================
//   PARAMETER & INTEGER DECLARATION
//================================================================
real    CYCLE = `CYCLE_TIME;
integer total_latency, latency;
integer out_val_clk_times;
integer i_pat;
integer l,m,n,o,p,q,r;
//================================================================
// wire & registers 
//================================================================
reg mode;

reg [4:0] data_weight[0:15];
reg [3:0] data_left[0:15];
reg [3:0] data_right[0:15];
reg [6:0] data_code[0:15];
reg [2:0] data_len[0:15];

reg [5:0] sort_wght[0:7];
reg [3:0] sort_char[0:7];
reg [3:0] sort_out[0:7];

reg [34:0] ans;
reg [5:0]  ans_count;
//================================================================
// clock
//================================================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;

//================================================================
// initial
//================================================================
initial begin
  reset_signal_task;
  total_latency = 0;
  i_pat = 0;
  // for(mode = 0;mode < 2; mode = mode + 1)begin
  //   for(data_weight[0] = 0;data_weight[0] < 8; data_weight[0] = data_weight[0] + 1)begin
  //     for(data_weight[1] = 0;data_weight[1] < 8; data_weight[1] = data_weight[1] + 1)begin
  //       for(data_weight[2] = 0;data_weight[2] < 8; data_weight[2] = data_weight[2] + 1)begin
  //         for(data_weight[3] = 0;data_weight[3] < 8; data_weight[3] = data_weight[3] + 1)begin
  //           for(data_weight[4] = 0;data_weight[4] < 8; data_weight[4] = data_weight[4] + 1)begin
  //             for(data_weight[5] = 0;data_weight[5] < 8; data_weight[5] = data_weight[5] + 1)begin
  //               for(data_weight[6] = 0;data_weight[6] < 8; data_weight[6] = data_weight[6] + 1)begin
  //                 for(data_weight[7] = 0;data_weight[7] < 8; data_weight[7] = data_weight[7] + 1)begin
  //                   gen_pattern;
  //                   input_task;
  //                   wait_out_valid_task;
  //                   check_ans_task;
  //                   total_latency = total_latency + latency;
  //                   i_pat = i_pat + 1;
  //                 end
  //               end
  //             end
  //           end
  //         end
  //       end
  //     end
  //   end
  // end
  for (i_pat = 0; i_pat < `PAT_NUM; i_pat = i_pat + 1) begin
    gen_pattern;
    input_task;
    wait_out_valid_task;
    check_ans_task;
    total_latency = total_latency + latency;
  end

  YOU_PASS_task;
end

initial begin
  while(1) begin
    if((out_valid === 0) && (out_code !== 0))
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be reset when out_valid is low.                *");
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

  rst_n       = 0;
  in_valid    = 0;
  in_weight   = 'bx;
  out_mode    = 'bx;
  #(10 * CYCLE);

  if( (out_valid !== 0) || (out_code !== 0) )
  begin
    $display("***********************************************************************");
    $display("*  Error                                                              *");
    $display("*  Output signal should reset after initial RESET                     *");
    $display("***********************************************************************");
    // DO NOT PUT @(negedge clk) HERE
    $finish;
  end
  #(CYCLE);  rst_n=1;
  #(CYCLE);  release clk;
end 
endtask

task gen_pattern;
begin
  if(i_pat < 2) mode = i_pat;
  else mode = $urandom() % 2; // 0, 1

  // weight
  if(i_pat < 2) begin
    data_weight[0] = 3;
    data_weight[1] = 7;
    data_weight[2] = 6;
    data_weight[3] = 5;
    data_weight[4] = 3;
    data_weight[5] = 3;
    data_weight[6] = 5;
    data_weight[7] = 7;
  end
  else begin
    for(integer i = 0; i < 8; i = i + 1) begin
      data_weight[i] = $urandom() % 8; // 0 ~ 7
    end
  end
  for(integer i = 8; i < 15; i = i + 1) begin
    data_weight[i] = 0;
  end
  data_weight[15] = 31;
  // reset other data
  for(integer i = 0; i < 16; i = i + 1) begin
    data_left[i]   = 15;
    data_right[i]  = 15;
    data_code[i]   = 0;
    data_len[i]    = 0;
  end

  // generate huffman tree
  for(integer i = 0; i < 7; i = i + 1) begin
    // assign sort_data
    if (i == 0) for (integer j = 0; j < 8; j = j + 1) begin
      sort_wght[j] = data_weight[j];
      sort_char[j] = j;
    end
    else begin
      sort_wght[0] = 31;
      sort_char[0] = 15;
      sort_wght[7] = data_weight[i + 7];
      sort_char[7] = i + 7;
      for (integer j = 1; j < 7; j = j + 1) begin
        sort_char[j] = sort_out[j-1];
        sort_wght[j] = data_weight[sort_out[j-1]];
      end
    end
    for (integer j = 0; j < 8; j = j + 1) begin
      sort_out[j] = sort_char[j];
    end
    //$display("i = %d", i);
    //$display("sort_wght = %d, %d, %d, %d, %d, %d, %d, %d", sort_wght[0], sort_wght[1], sort_wght[2], sort_wght[3], sort_wght[4], sort_wght[5], sort_wght[6], sort_wght[7]);
    //$display("sort_char = %d, %d, %d, %d, %d, %d, %d, %d", sort_char[0], sort_char[1], sort_char[2], sort_char[3], sort_char[4], sort_char[5], sort_char[6], sort_char[7]);
    // sort
    for(integer j = 0; j < 7; j = j + 1) begin
      for(integer k = 0; k < 7; k = k + 1) begin
        if(sort_wght[k] < sort_wght[k+1]) begin
          integer temp;
          temp = sort_wght[k];
          sort_wght[k] = sort_wght[k+1];
          sort_wght[k+1] = temp;
          temp = sort_out[k];
          sort_out[k] = sort_out[k+1];
          sort_out[k+1] = temp;
        end
      end
    end
    //$display("sort_wght = %d, %d, %d, %d, %d, %d, %d, %d", sort_wght[0], sort_wght[1], sort_wght[2], sort_wght[3], sort_wght[4], sort_wght[5], sort_wght[6], sort_wght[7]);
    //$display("sort_out = %d, %d, %d, %d, %d, %d, %d, %d", sort_out[0], sort_out[1], sort_out[2], sort_out[3], sort_out[4], sort_out[5], sort_out[6], sort_out[7]);
    // merge
    data_weight[i + 8] = sort_wght[6] + sort_wght[7];
    data_left[i + 8]   = sort_out[6];
    data_right[i + 8]  = sort_out[7];
    
  end
  
  // (debug) view tree
  //for(integer i = 0; i < 16; i = i + 1) begin
  //  $display("data_weight[%2d] = %2d, data_left[%2d] = %2d, data_right[%2d] = %2d", i, data_weight[i], i, data_left[i], i, data_right[i]);
  //end

  // encode
  for(integer i = 14; i >= 8; i = i - 1) begin
    integer left, right;
    left  = data_left[i];
    right = data_right[i];
    for(integer j = 0; j < data_len[i]; j = j + 1) begin
      data_code[left][j]  = data_code[i][j];
      data_len[left] = data_len[left] + 1;
      data_code[right][j] = data_code[i][j];
      data_len[right] = data_len[right] + 1;
    end
    data_code[left][data_len[left]]  = 0;
    data_len[left] = data_len[left] + 1;
    data_code[right][data_len[right]] = 1;
    data_len[right] = data_len[right] + 1;
  end

  // (debug) view encode
  //for(integer i = 0; i < 8; i = i + 1) begin
  //  $write("%d: ", i);
  //  for(integer j = 0; j < data_len[i]; j = j + 1) begin
  //    $write("%d", data_code[i][j]);
  //  end
  //  $display("");
  //end

  // gen ans
  ans_count = 0;
  ans = 'bx;
  if(mode == 0) begin // mode 0: 45673
    for(integer i = 0; i < data_len[4]; i = i + 1) begin
      ans[ans_count] = data_code[4][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[5]; i = i + 1) begin
      ans[ans_count] = data_code[5][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[6]; i = i + 1) begin
      ans[ans_count] = data_code[6][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[7]; i = i + 1) begin
      ans[ans_count] = data_code[7][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[3]; i = i + 1) begin
      ans[ans_count] = data_code[3][i];
      ans_count = ans_count + 1;
    end
  end
  else begin // mode 1: 42501
    for(integer i = 0; i < data_len[4]; i = i + 1) begin
      ans[ans_count] = data_code[4][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[2]; i = i + 1) begin
      ans[ans_count] = data_code[2][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[5]; i = i + 1) begin
      ans[ans_count] = data_code[5][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[0]; i = i + 1) begin
      ans[ans_count] = data_code[0][i];
      ans_count = ans_count + 1;
    end
    for(integer i = 0; i < data_len[1]; i = i + 1) begin
      ans[ans_count] = data_code[1][i];
      ans_count = ans_count + 1;
    end
  end
end
endtask

task input_task; 
begin
  repeat($urandom() % 3 + 2) @(negedge clk);
  in_valid  = 1'b1;
  in_weight = data_weight[0];
  out_mode  = mode;
  @(negedge clk);

  for(integer i = 1; i < 8; i = i + 1) begin
    in_weight = data_weight[i];
    out_mode  = 'dx;
    @(negedge clk);
  end

  // Disable input
  in_valid  = 'b0;
  in_weight = 'bx;
  out_mode  = 'bx;
end
endtask

task wait_out_valid_task;
begin
  latency = 0;
  while(out_valid !== 1) begin
    latency = latency + 1;
    if(latency >= 2000)
    begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The execution latency are over 2,000 cycles.                       *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
end
endtask

task check_ans_task;
begin

  for(integer i = 0; i < ans_count; i = i + 1) begin
    if(~out_valid) begin
      $display("***********************************************************************");
      $display("*  Error:                                                             *");
      $display("*  out_valid mantain too short                                        *");
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end 

    if(out_code !== ans[i]) begin
      $display("***********************************************************************");
      $display("*  Error                                                              *");
      $display("*  The out_data should be correct when out_valid is high              *");
      $display("*  Your        : %1b                                                    *", out_code);
      $display("*  Gloden      : %1b                                                    *", ans[i]);
      $display("***********************************************************************");
      repeat(2)@(negedge clk);
      $finish;
    end
    @(negedge clk);
  end
  
  @(negedge clk);
  if(out_valid) begin
    $display("***********************************************************************");
    $display("*  Error:                                                             *");
    $display("*  out_valid mantain too long                                         *");
    $display("***********************************************************************");
    repeat(2)@(negedge clk);
    $finish;
  end   
  
  $display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32mexecution cycle : %4d\033[m", i_pat, latency);
  repeat(3)@(negedge clk);
end endtask

task YOU_PASS_task; begin
  $display("***********************************************************************");
  $display("*                           \033[0;32mCongratulations!\033[m                          *");
  $display("*  Your execution cycles = %18d   cycles                *", total_latency);
  $display("*  Your clock period     = %20.1f ns                    *", CYCLE);
  $display("*  Total Latency         = %20.1f ns                    *", total_latency*CYCLE);
  $display("***********************************************************************");
  $finish;
end endtask

endmodule