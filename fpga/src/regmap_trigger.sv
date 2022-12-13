
module regmap_trigger
  ( input  logic       clk,
    input  logic       rst_n_sync,
    input  logic [7:0] address,
    input  logic       trigger_write_enable,
    input  logic [7:0] write_data_in,
    input  logic       trigger_read_enable,
    output logic [7:0] trigger_read_data,
    output logic       cfg_positive,
    output logic [2:0] cfg_type,
    output logic [4:0] cfg_stage1_count,
    output logic [2:0] cfg_time_base,
    output logic [7:0] cfg_count1,
    output logic [7:0] cfg_count2,
    output logic       cfg_longer_no_edge,
    output logic       cfg_trig_dur_sel,
    output logic       cfg_enable
    );
    
    logic [7:0] registers[8:0]; // 9 address, holding 8bits
    
    assign trigger_read_data[7:0] =  ({8{trigger_read_enable}} & registers[address]);
    
    // each cfg register has its own address, just to keep things simple
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) begin cfg_positive       <= 1'b0;
                             cfg_type           <= 3'd0;
                             cfg_stage1_count   <= 5'd0;
                             cfg_time_base      <= 3'd0;
                             cfg_count1         <= 8'd0;
                             cfg_count2         <= 8'd0;
                             cfg_longer_no_edge <= 1'b0;
                             cfg_trig_dur_sel   <= 1'b0;
                             cfg_enable         <= 1'b0; end
      else if (trigger_write_enable && (address == 'd0)) cfg_positive       <= write_data_in[0];
      else if (trigger_write_enable && (address == 'd1)) cfg_type           <= write_data_in[2:0];
      else if (trigger_write_enable && (address == 'd2)) cfg_stage1_count   <= write_data_in[4:0];
      else if (trigger_write_enable && (address == 'd3)) cfg_time_base      <= write_data_in[2:0];
      else if (trigger_write_enable && (address == 'd4)) cfg_count1         <= write_data_in[7:0];
      else if (trigger_write_enable && (address == 'd5)) cfg_count2         <= write_data_in[7:0];
      else if (trigger_write_enable && (address == 'd6)) cfg_longer_no_edge <= write_data_in[0];
      else if (trigger_write_enable && (address == 'd7)) cfg_trig_dur_sel   <= write_data_in[0];
      else if (trigger_write_enable && (address == 'd8)) cfg_enable         <= write_data_in[0];
    
    // this is used for read_data_out decode
    assign registers[0] = {7'd0,cfg_positive};
    assign registers[1] = {5'd0,cfg_type};
    assign registers[2] = {3'd0,cfg_stage1_count};
    assign registers[3] = {5'd0,cfg_time_base};
    assign registers[4] = cfg_count1;
    assign registers[5] = cfg_count2;
    assign registers[6] = {7'd0,cfg_longer_no_edge};
    assign registers[7] = {7'd0,cfg_trig_dur_sel};
    assign registers[8] = {7'd0,cfg_enable};
    
endmodule
