
module trigger
  ( input  logic       clk,                // fpga clk
    input  logic       rst_n_sync,         // active-low reset
    input  logic       trigger_source,     // this is the signal to be examined based on cfg_type
    output logic       trigger_out,        // is high for either 10 or 100 fpga clock cycles when trigger driven
    input  logic       cfg_positive,       // high is positive edge, else negedge
    input  logic [2:0] cfg_type,           // types 0 thru 4: 0 is edge only, 1 is less than, 2 is greater than, 3 is inside window, 4 is outside window
    input  logic [7:0] cfg_count1,         // this is used for cfg_type 1, 2, 3 and 4
    input  logic [7:0] cfg_count2,         // this is used for cfg_type 3 and 4
    input  logic [4:0] cfg_stage1_count,   // this adapts a fpga clk frequency to a base 10 value
    input  logic [2:0] cfg_time_base,      // selects the timebase for count1 and count2 values
    input  logic       cfg_longer_no_edge, // if high a cfg_type 2 count above count1 will trigger, a cfg_type 3 count above count2 will trigger
    input  logic       cfg_trig_dur_sel,   // if high trigger duration is 100 FPGA clock cycles, else 10 cycles
    input  logic       cfg_enable          // high enables the trigger_out output, else always low
    );
    
    logic        hold_trigger_source;        // used for edge detect
    logic [23:0] time_base_cnt;              // large counter which starts counting when an edge has been seen
    logic [23:0] end_time_base_cnt;          // this count is selected by cfg_time_base and cfg_12mhz
    logic        pos_edge;                   // positive edge detected
    logic        neg_edge;                   // negative edge detected
    logic        en_time_base_cnt;           // enable the time base counter
    logic        toggle_time_base;           // end_time_base_cnt reached by time_base_cnt
    logic [7:0]  count;                      // main counter which increments on toggle_time_base
    logic        opposite_edge;              // the edge opposite to cfg_positive has been seen
    logic        type0_trig;                 // valid criteria for type 0 trigger seen
    logic        type1_trig;                 // valid criteria for type 1 trigger seen
    logic        type2_trig;                 // valid criteria for type 2 trigger seen
    logic        type3_trig;                 // valid criteria for type 3 trigger seen
    logic        type4_trig;                 // valid criteria for type 4 trigger seen
    logic        any_trig;                   // any valid trigger seen
    logic [6:0]  trig_duration;              // counter used to keep trigger_out high
    logic        trigger_source_sync;        // synchronized trigger_source
    logic        cfg_enable_sync;            // in case the trigger clock is differnt to regmap clock
    logic        trigger_out_ff;             // flopped trigger_out, which is 1 fpga clock slow
    logic [4:0]  stage1_counter;             // stage1_counter counter to adjust the fpga clk to a base 10 equivalent
    logic [4:0]  final_stage1_count;         // adjusted final value for the stage1_count
    logic        reached_final_stage1_count; // when this is true the time_base_cnt can increment
    logic [6:0]  trig_end_cnt;               // duration of trigger_out, selectable

    // synchronizer to ensure that noisy gpio input does not cause metastability
    synchronizer u_synchronizer_gpio_in
      ( .clk      (clk),
        .rst_n    (rst_n_sync),
        .data_in  (trigger_source),
        .data_out (trigger_source_sync) // synchronized output
       );

    synchronizer u_synchronizer_cfg_enable
      ( .clk      (clk),
        .rst_n    (rst_n_sync),
        .data_in  (cfg_enable),
        .data_out (cfg_enable_sync) // synchronized output
       );

    // flipflop used for edge detect
    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) hold_trigger_source <= 1'b0;
      else             hold_trigger_source <= trigger_source_sync & cfg_enable_sync;

    assign pos_edge = ( trigger_source_sync && ~hold_trigger_source);
    assign neg_edge = (~trigger_source_sync &&  hold_trigger_source);

    assign opposite_edge = (cfg_positive && neg_edge) || (~cfg_positive && pos_edge);

    // type0 is no counter, just pos or neg edge
    // type1 is shorter than count1
    // type2 is longer than count1
    // type3 is more than count1 and less than count2 (inside)
    // type4 is less than count1 or more than count2 (outside)
    assign type0_trig = (cfg_type == 3'd0) && ((cfg_positive && pos_edge) || (~cfg_positive && neg_edge));
    assign type1_trig = en_time_base_cnt && (cfg_type == 3'd1) && (count <= cfg_count1) &&                           opposite_edge;
    assign type2_trig = en_time_base_cnt && (cfg_type == 3'd2) && (count >= cfg_count1) && (cfg_longer_no_edge    || opposite_edge);
    assign type3_trig = en_time_base_cnt && (cfg_type == 3'd3) && (count >= cfg_count1) && (count <= cfg_count2)  && opposite_edge;
    assign type4_trig = en_time_base_cnt && (cfg_type == 3'd4) && 
                        (((count <= cfg_count1) && opposite_edge) || ((count >= cfg_count2) && (cfg_longer_no_edge || opposite_edge)));
    
    assign any_trig   = type0_trig || type1_trig || type2_trig || type3_trig || type4_trig;

    // enable time base counter when valid edge is seen, 
    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                   en_time_base_cnt <= 1'b0;
      else if ((cfg_type == 3'd0) || (~cfg_enable_sync)) en_time_base_cnt <= 1'b0; // never count on a type 0
      else if (trigger_out)                              en_time_base_cnt <= 1'b0; // stop counting when the trigger has been driven
      else if ( cfg_positive && pos_edge)                en_time_base_cnt <= 1'b1; // this is a valid event to start counting
      else if ( cfg_positive && neg_edge)                en_time_base_cnt <= 1'b0; // we stop counting here
      else if (~cfg_positive && neg_edge)                en_time_base_cnt <= 1'b1; // this is a valid event to start counting
      else if (~cfg_positive && pos_edge)                en_time_base_cnt <= 1'b0; // we stop counting here
      
    always_comb
        if (cfg_stage1_count > 5'd0)  final_stage1_count = cfg_stage1_count - 5'd1;
        else                          final_stage1_count = 5'd0;
    
    assign reached_final_stage1_count = (stage1_counter == final_stage1_count);
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                                        stage1_counter <= '0;
      else if (!en_time_base_cnt || (cfg_type == 3'd0) || (~cfg_enable_sync)) stage1_counter <= '0;
      else if (!reached_final_stage1_count)                                   stage1_counter <= stage1_counter + 1;
      else if ( reached_final_stage1_count)                                   stage1_counter <= '0;

    // this depends on the FPGA board clock
    always_comb
      case(cfg_time_base)
        3'd0: end_time_base_cnt = 0;                // stage1 * 10
        3'd1: end_time_base_cnt = 24'd10 - 1;       // stage1 * 100
        3'd2: end_time_base_cnt = 24'd100 - 1;      // stage1 * 1E3
        3'd3: end_time_base_cnt = 24'd1000 - 1;     // stage1 * 1E4
        3'd4: end_time_base_cnt = 24'd10000 - 1;    // stage1 * 1E5
        3'd5: end_time_base_cnt = 24'd100000 - 1;   // stage1 * 1E6
        3'd6: end_time_base_cnt = 24'd1000000 - 1;  // stage1 * 1E7
        3'd7: end_time_base_cnt = 24'd10000000 - 1; // stage1 * 1E8
      endcase

    //assign toggle_time_base = (time_base_cnt == end_time_base_cnt);
    // adjust the final time_base_cnt to have one less fpga clock on the last comparison as the trigger_out will be driven 1 clock later
    always_comb
      if      (cfg_time_base == '0)                                               toggle_time_base = 1;
      else if ((cfg_count1 > 0) && (cfg_type > 0) && (count == (cfg_count1 - 1))) toggle_time_base = (time_base_cnt == (end_time_base_cnt - 1));
      else if ((cfg_count2 > 0) && (cfg_type > 2) && (count == (cfg_count2 - 1))) toggle_time_base = (time_base_cnt == (end_time_base_cnt - 1));
      else                                                                        toggle_time_base = (time_base_cnt == end_time_base_cnt);

    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                                            time_base_cnt <= '0;
      else if (!en_time_base_cnt || (cfg_time_base == '0))                        time_base_cnt <= '0; // no valid edge seen, so don't count
      else if (toggle_time_base)                                                  time_base_cnt <= '0; // reached final count
      else if ((time_base_cnt < end_time_base_cnt) && reached_final_stage1_count) time_base_cnt <= time_base_cnt + 1; // count is enabled, final not reached so count

    // 8 bit count allows values 0 to 255
    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                                                  count <= 'd0;
      else if (!en_time_base_cnt)                                                       count <= 'd0;
      else if ((cfg_time_base == '0) && reached_final_stage1_count && (count < 8'd255)) count <= count + 1; // this will count when cfg_time_base == 0
      else if ((cfg_time_base > 0)   && (toggle_time_base)         && (count < 8'd255)) count <= count + 1; // this will count when cfg_time_base != 0

    assign trig_end_cnt = (cfg_trig_dur_sel) ? 7'd99 : 7'd9;

    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                        trigger_out <= 1'b0;
      else if (trig_duration == trig_end_cnt) trigger_out <= 1'b0;
      else if (any_trig)                      trigger_out <= 1'b1;
      
    always@(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                trig_duration <= 'd0;
      else if (trig_duration == trig_end_cnt)         trig_duration <= 'd0;
      else if (trigger_out && (trig_duration == 'd0)) trig_duration <= 'd1;
      else if (trigger_out && (trig_duration > 0))    trig_duration <= trig_duration + 1;

endmodule