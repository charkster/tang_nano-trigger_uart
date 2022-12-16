// cfg_enable_pat_gen is the last address, such that a single block write can configure and enable the pattern

module regmap_pattern_gen
  ( input  logic       clk,
    input  logic       rst_n_sync,
    input  logic [7:0] address,
    input  logic       pat_gen_write_enable,
    input  logic [7:0] write_data_in,
    input  logic       pat_gen_read_enable,
    output logic [7:0] pat_gen_read_data,
    output logic [7:0] cfg_end_address_pat_gen,
    output logic [1:0] cfg_num_gpio_sel_pat_gen,
    output logic [2:0] cfg_timestep_sel_pat_gen,
    output logic [4:0] cfg_stage1_count_sel_pat_gen,
    output logic       cfg_repeat_enable_pat_gen,
    output logic       cfg_enable_pat_gen
    );
    
    logic [7:0] registers[5:0]; // width is first, number of registers is second
    
    assign pat_gen_read_data[7:0] =  ({8{pat_gen_read_enable}} & registers[address]);
    
    // each cfg register has its own address, just to keep things simple
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) begin cfg_end_address_pat_gen      <= 8'd0;
                             cfg_repeat_enable_pat_gen    <= 1'd0;
                             cfg_num_gpio_sel_pat_gen     <= 2'd0;
                             cfg_timestep_sel_pat_gen     <= 3'd0;
                             cfg_stage1_count_sel_pat_gen <= 5'd0; 
                             cfg_enable_pat_gen           <= 1'd0; end
      else begin
           if (pat_gen_write_enable && (address == 'd0)) cfg_end_address_pat_gen      <= write_data_in[7:0];
           if (pat_gen_write_enable && (address == 'd1)) cfg_num_gpio_sel_pat_gen     <= write_data_in[1:0];
           if (pat_gen_write_enable && (address == 'd2)) cfg_timestep_sel_pat_gen     <= write_data_in[2:0];
           if (pat_gen_write_enable && (address == 'd3)) cfg_stage1_count_sel_pat_gen <= write_data_in[4:0];
           if (pat_gen_write_enable && (address == 'd4)) cfg_repeat_enable_pat_gen    <= write_data_in[0];
           if (pat_gen_write_enable && (address == 'd5)) cfg_enable_pat_gen           <= write_data_in[0]; end
    
    // this is used for read_data_out decode
    assign registers[0] = cfg_end_address_pat_gen;
    assign registers[1] = {6'd0,cfg_num_gpio_sel_pat_gen};
    assign registers[2] = {5'd0,cfg_timestep_sel_pat_gen};
    assign registers[3] = {3'd0,cfg_stage1_count_sel_pat_gen};
    assign registers[4] = {7'd0,cfg_repeat_enable_pat_gen};
    assign registers[5] = {7'd0,cfg_enable_pat_gen};

    
endmodule