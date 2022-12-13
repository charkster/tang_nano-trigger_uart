
module trigger_uart_top (
  input  logic       clk_27mhz,
  input  logic       button_s1,
  input  logic       uart_rx,
  output logic       uart_tx,
  input  logic       trigger_source,
  output logic       trigger_out,
  output logic [7:0] gpio_pat_gen_out,
  output logic       led_1,
  output logic       led_2,
  output logic       led_3,
  output logic       led_4,
  output logic       led_5,
  output logic       led_6
);

  parameter NUM_ADDR_BYTES   = 1;
  parameter RAM_ADDR_BITS    = 8;
  parameter TRIGGER_SLAVE_ID = 7'd01;
  parameter PAT_GEN_SLAVE_ID = 7'd02;
  parameter BRAM_SLAVE_ID    = 7'd03;

  logic       rst_n;
  logic       valid_slave_id;
  logic       clk_100mhz;
  logic       rst_n_sync;
  logic       read_enable;
  logic       write_enable;
  logic       trigger_read_enable;
  logic       trigger_write_enable;
  logic       rx_block_timeout;
  logic       rx_data_valid;
  logic [7:0] rx_data_out;
  logic       tx_trig;
  logic       tx_bsy;
  logic [7:0] send_data;
  logic [6:0] slave_id;
  logic       send_slave_id;
  logic [7:0] read_data;
  logic [7:0] trigger_read_data;
  logic [7:0] pat_gen_read_data;
  logic [7:0] bram_read_data;
  logic       rx_bsy;
  logic [26:0] led_counter;
  logic       pattern_active;

  logic [NUM_ADDR_BYTES*8-1:0] address;

  // generate 100mhz clock, actual frequency is 100.2 MHz
  Gowin_rPLL u_Gowin_rPLL_100mhz
    ( .clkout (clk_100mhz), 
      .clkin  (clk_27mhz)
     );

  assign rst_n = button_s1;

  synchronizer u_synchronizer_rst_n_sync
    ( .clk      (clk_100mhz), // input
      .rst_n    (rst_n),      // input
      .data_in  (1'b1),       // input
      .data_out (rst_n_sync)  // output
     );

  // this should be high for any valid slave id used, if the pattern_gen block is active pattern_gen and bram are not valid
  assign valid_slave_id = (slave_id == TRIGGER_SLAVE_ID) || (((slave_id == PAT_GEN_SLAVE_ID) || (slave_id == BRAM_SLAVE_ID)) && (!pattern_active));

  uart_tx 
  # ( .SYSCLOCK( 100.0 ), .BAUDRATE( 3.0 ) ) // MHz and Mbits
  u_uart_tx
    ( .clk       (clk_100mhz),                // input
      .rst_n     (rst_n_sync),                // input
      .send_trig (tx_trig && valid_slave_id), // input
      .send_data,                             // input [7:0]
      .tx        (uart_tx),                   // output
      .tx_bsy                                 // output
     );

  uart_rx
  # ( .SYSCLOCK( 100.0 ), .BAUDRATE( 3.0 ) ) // MHz and Mbits
  u_uart_rx
    ( .clk           (clk_100mhz),       // input
      .rst_n         (rst_n_sync),       // input
      .rx            (uart_rx),          // input
      .rx_bsy,                           // output
      .block_timeout (rx_block_timeout), // output
      .data_valid    (rx_data_valid),    // output
      .data_out      (rx_data_out)       // output [7:0]
     );

  // this block can allow for multiple memories to be accessed,
  // but as the address width is fixed, smaller memories will need to
  // zero pad the upper address bits not used (this is done in python)
  uart_byte_regmap_interface
  # ( .NUM_ADDR_BYTES(NUM_ADDR_BYTES) )
  u_uart_byte_regmap_interface
    ( .clk          (clk_100mhz), // input
      .rst_n        (rst_n_sync), // input
      .rx_data_out,               // input [7:0]
      .rx_data_valid,             // input
      .rx_block_timeout,          // input
      .tx_bsy,                    // input
      .tx_trig,                   // output
      .slave_id,                  // output [6:0]
      .address,                   // output [NUM_ADDR_BYTES*8-1:0]
      .write_enable,              // output
      .read_enable,               // output
      .send_slave_id              // output
     );

  // each regmap is responsible for driving zeros on the read data when their read_enable is inactive
  assign read_data = trigger_read_data | pat_gen_read_data | bram_read_data;
  
  // first uart byte of data to send is an read_enable and slave_id, then requested read data will be sent
  assign send_data = (send_slave_id) ? {read_enable,slave_id} : read_data;

  assign trigger_write_enable = write_enable && (slave_id == TRIGGER_SLAVE_ID);
  assign trigger_read_enable  = read_enable  && (slave_id == TRIGGER_SLAVE_ID);

  // configuration registers from scarf_regmap_trigger
  logic       cfg_positive;
  logic [2:0] cfg_type;
  logic [7:0] cfg_count1;
  logic [7:0] cfg_count2;
  logic [4:0] cfg_stage1_count;
  logic [2:0] cfg_time_base;
  logic       cfg_longer_no_edge;
  logic       cfg_trig_dur_sel;
  logic       cfg_enable;
  
  regmap_trigger u_regmap_trigger
  ( .clk             (clk_100mhz),  // input
    .rst_n_sync      (rst_n_sync),  // input
    .address,                       // input [7:0]
    .trigger_write_enable,          // input
    .write_data_in   (rx_data_out), // input [7:0]
    .trigger_read_enable,           // input
    .trigger_read_data,             // output [7:0]
    .cfg_positive,                  // output
    .cfg_type,                      // output [2:0]
    .cfg_count1,                    // output [7:0]
    .cfg_count2,                    // output [7:0]
    .cfg_stage1_count,              // output [4:0]
    .cfg_time_base,                 // output [2:0]
    .cfg_longer_no_edge,            // output
    .cfg_trig_dur_sel,              // output
    .cfg_enable                     // output
   );
    
  // only cfg_enable is synchronized
  trigger u_trigger
  ( .clk              (clk_100mhz), // input
    .rst_n_sync       (rst_n_sync), // input
    .trigger_source,                // input
    .trigger_out,                   // output
    .cfg_positive,                  // input
    .cfg_type,                      // input [2:0]
    .cfg_count1,                    // input [7:0]
    .cfg_count2,                    // input [7:0]
    .cfg_stage1_count,              // input [4:0]
    .cfg_time_base,                 // input [2:0]
    .cfg_longer_no_edge,            // input
    .cfg_trig_dur_sel,              // input
    .cfg_enable                     // input
   );

  logic       pat_gen_write_enable;
  logic       pat_gen_read_enable;
  logic       cfg_enable_pat_gen;
  logic       cfg_repeat_enable_pat_gen;
  logic [1:0] cfg_num_gpio_sel_pat_gen;
  logic [2:0] cfg_timestep_sel_pat_gen;
  logic [4:0] cfg_stage1_count_sel_pat_gen;
  logic       pattern_done;
  logic [RAM_ADDR_BITS-1:0] ram_addr_pat_gen;
  logic [RAM_ADDR_BITS-1:0] cfg_end_address_pat_gen;
  
  assign pat_gen_write_enable = write_enable && (slave_id == PAT_GEN_SLAVE_ID);
  assign pat_gen_read_enable  = read_enable  && (slave_id == PAT_GEN_SLAVE_ID);

  regmap_pattern_gen 
  u_regmap_pattern_gen
  ( .clk             (clk_100mhz),  // input
    .rst_n_sync      (rst_n_sync),  // input
    .address,                       // input [7:0]
    .pat_gen_write_enable,          // input
    .write_data_in   (rx_data_out), // input [7:0]
    .pat_gen_read_enable,           // input
    .pat_gen_read_data,             // output [7:0]
    .cfg_end_address_pat_gen,       // output [7:0] // THIS IS NOT PARAMETERIZED WITHIN THE REGMAP!!!
    .cfg_num_gpio_sel_pat_gen,      // output [1:0]
    .cfg_timestep_sel_pat_gen,      // output [2:0]
    .cfg_stage1_count_sel_pat_gen,  // output [4:0]
    .cfg_repeat_enable_pat_gen,     // output
    .cfg_enable_pat_gen             // output
   );
      
   pattern_gen 
   # ( .RAM_ADDR_BITS(RAM_ADDR_BITS) )
   u_pattern_gen
   ( .clk                 (clk_100mhz),     // input
     .rst_n               (rst_n_sync),     // input
     .cfg_end_address_pat_gen,              // input  [RAM_ADDR_BITS-1:0]
     .cfg_num_gpio_sel_pat_gen,             // input  [1:0]
     .cfg_timestep_sel_pat_gen,             // input  [2:0]
     .cfg_stage1_count_sel_pat_gen,         // input  [4:0]
     .cfg_repeat_enable_pat_gen,            // input
     .cfg_enable_pat_gen,                   // input
     .pattern_active,                       // output
     .pattern_done,                         // output
     .gpio_pat_gen_out,                     // output [7:0]
     .ram_data            (bram_read_data), // input  [7:0]
     .ram_addr_pat_gen                      // output [RAM_ADDR_BITS-1:0]
    );

  logic bram_read_enable;
  logic bram_write_enable;
  logic [RAM_ADDR_BITS-1:0] bram_address;

// multiple memories could be used, all with different slave_ids
  assign bram_read_enable  = (read_enable  && (slave_id == BRAM_SLAVE_ID)) || pattern_active;
  assign bram_write_enable = (write_enable && (slave_id == BRAM_SLAVE_ID));

  assign bram_address = (pattern_active) ? ram_addr_pat_gen : address;

  block_ram
  # ( .RAM_WIDTH(8), .RAM_ADDR_BITS(RAM_ADDR_BITS) )
  u_block_ram
    ( .clk          (clk_100mhz),         // input
      .write_enable (bram_write_enable),  // input 
      .address      (bram_address),       // input [RAM_ADDR_BITS-1:0]
      .write_data   (rx_data_out),        // input [7:0]
      .read_enable  (bram_read_enable),   // input
      .read_data    (bram_read_data)      // output [7:0]
     );

  // led_counter will help drive the orange LEDs, which show that a trigger_out occured
  // 27bit counter overflows in (134,000,000)/(100,000,000) = 1.34 seconds
  always_ff @(posedge clk_100mhz, negedge rst_n_sync)
    if (~rst_n_sync)                             led_counter <= 'd0;
    else if (trigger_out && (led_counter == '0)) led_counter <= 'd1;
    else if (led_counter > 'd0)                  led_counter <= led_counter + 1; // overflow expected

  always_comb begin
    led_1 = (led_counter == 0);
    led_2 = (led_counter < 'd25000000);
    led_3 = (led_counter < 'd50000000);
    led_4 = (led_counter < 'd75000000);
    led_5 = (led_counter < 'd100000000);
    led_6 = (led_counter < 'd125000000);
  end

endmodule