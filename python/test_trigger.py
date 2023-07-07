#!/usr/bin/python

import time
from scarf_uart_slave import scarf_uart_slave

trigger  = scarf_uart_slave(slave_id=0x01, num_addr_bytes=1, debug=False)
pat_gen  = scarf_uart_slave(slave_id=0x02, num_addr_bytes=1, debug=False)
bram     = scarf_uart_slave(slave_id=0x03, num_addr_bytes=1, debug=False)

# FROM RTL, PATTERN_GEN
# assign registers[0] = cfg_end_address_pat_gen;             // this is one greater than the bram address
# assign registers[1] = {6'd0,cfg_num_gpio_sel_pat_gen};     // 2'b00 is 1 pin, 2'b01 is 2 pins, 2'b10 is 4 pins and 2'b11 is 8 pins
# assign registers[2] = {5'd0,cfg_timestep_sel_pat_gen};     // 3'b000 is 1x, 3'b001 is 10x, 3'b010 is 100x, 3'b011 is 1000x, etc...
# assign registers[3] = {3'd0,cfg_stage1_count_sel_pat_gen}; // if your fpga clock is 27MHz, you can set this to 5'd27, a divide by 27 to get 1MHz
# assign registers[4] = {7'd0,cfg_repeat_enable_pat_gen};    // when high this repeats the pattern until this bit is set low
# assign registers[5] = {7'd0,cfg_enable_pat_gen};           // rising edge starts the pattern, make sure this bit is low before it is set high again

# FROM RTL, TRIGGER
# assign registers[0] = {7'd0,cfg_positive};       // if high, trigger on positive edge, else trigger on negative edge
# assign registers[1] = {5'd0,cfg_type};           // types 0 thru 4... see type description
# assign registers[2] = {3'd0,cfg_stage1_count};   // if your fpga clock is 27MHz, you can set this to 5'd27, a divide by 27 to get 1MHz
# assign registers[3] = {5'd0,cfg_time_base};      // 3'b000 is 1x, 3'b001 is 10x, 3'b010 is 100x, 3'b011 is 1000x, etc...
# assign registers[4] = cfg_count1;                // depending on the trigger type, this is the first count value
# assign registers[5] = cfg_count2;                // depending on the trigger type, this is the second count value
# assign registers[6] = {7'd0,cfg_longer_no_edge}; // a high value enables a trigger without an edge, a timeout is used
# assign registers[7] = {7'd0,cfg_enable};         // a high value enables triggers to be driven

pat_gen_stage1    = 0 # no division
pat_gen_time_base = 3 # 10us
trigger_stage1    = 0 # no division
trigger_time_base = 2 # 1us

def type0_positive():
	print("pattern will trigger on positive edges, pattern is in 1us steps")
	#                                           positive=true, type=edge, stage1_count,   time_base=0us,     count1=0us, count2=0, longer_no_edge=false, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,             0,         trigger_stage1, trigger_time_base, 0,          0,        0,                    1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type0_negative():
	print("pattern will trigger on positive edges, pattern is in 1us steps")
	#                                           positive=false, type=edge, stage1_count,   time_base=0us,     count1=0us, count2=0, longer_no_edge=false, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              0,         trigger_stage1, trigger_time_base, 0,          0,        0,                    1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type1_positive():
	print("pattern will trigger on positive pulses shorter than 18us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=true,  type=shorter, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=false, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,              1,            trigger_stage1, trigger_time_base, 18,          0,        0,                    1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type1_negative():
	print("pattern will trigger on positive pulses short than 18us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=shorter, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              1,            trigger_stage1, trigger_time_base, 18,          0,        0,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type2_positive():
	print("pattern will trigger on positive pulses longer than 18us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=true, type=longer, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,             2,           trigger_stage1, trigger_time_base, 18,          0,        0,                   1,            1])
#	print(trigger.read_list(addr=0, num_bytes=8))
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
#	print(bram.read_list(addr=0, num_bytes=3))
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
#	print(pat_gen.read_list(addr=0, num_bytes=6))

def type2_positive_no_edge():
	print("pattern will trigger on positive pulses longer than 18us (as soon as 18us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=true, type=longer, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,             2,           trigger_stage1, trigger_time_base, 18,          0,        1,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type2_negative():
	print("pattern will trigger on negative pulses longer than 18us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=longer, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              2,           trigger_stage1, trigger_time_base, 18,          0,        0,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type2_negative_no_edge():
	print("pattern will trigger on negative pulses longer than 18us (as soon as 18us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=longer, stage1_count,   time_base=1us,     count1=19us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              2,           trigger_stage1, trigger_time_base, 18,          0,        1,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type3_positive():
	print("pattern will trigger on positive pulses longer than 18us and less than 28us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=true, type=inside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,             3,           trigger_stage1, trigger_time_base, 18,          28,       0,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type3_negative():
	print("pattern will trigger on negative pulses longer than 18us and less than 32us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=inside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              3,           trigger_stage1, trigger_time_base, 18,          32,       0,                   1,            1])
	bram.write_list(addr=0, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type4_positive():
	print("pattern will trigger on positive pulses less than 18us OR greater than 28us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=outside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0x00, write_byte_list=[1,             4,            trigger_stage1, trigger_time_base, 18,          28,       0,                   1,            1])
	bram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type4_positive_no_edge():
	print("pattern will trigger on positive pulses less than 18us OR greater than 28us (as soon as 28us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=true, type=outside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[1,             4,            trigger_stage1, trigger_time_base, 18,          29,       1,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type4_negative():
	print("pattern will trigger on negative pulses less than 18us OR greater than 28us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=outside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              4,            trigger_stage1, trigger_time_base, 18,          28,       0,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

def type4_negative_no_edge():
	print("pattern will trigger on negative pulses less than 18us OR greater than 28us (as soon as 28us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                           positive=false, type=outside, stage1_count,   time_base=1us,     count1=18us, count2=0, longer_no_edge=true, trig_dur_sel, enable=true
	trigger.write_list(addr=0, write_byte_list=[0,              4,            trigger_stage1, trigger_time_base, 18,          28,       1,                   1,            1])
	bram.write_list(addr=0,    write_byte_list=[0b11101101, 0b11101010, 0b00111110])
        #                                           end_address,  num_gpio, timestep,          stage1_count,   repeat_enable, enable
	pat_gen.write_list(addr=0, write_byte_list=[3,            0,        pat_gen_time_base, pat_gen_stage1, 0,             1])
	pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, needed as positive edge starts pattern

print("These slave_ids need to be correct or FPGA is not connected/programmed")
print("trigger slave id is 0x{:02x}".format(trigger.read_id()))
print("pat_gen slave id is 0x{:02x}".format(pat_gen.read_id()))
print("bram    slave id is 0x{:02x}".format(bram.read_id()))


# Select one of the above functions to verify
type2_positive()
time.sleep(0.5)
pat_gen.write_list(addr=5, write_byte_list=[0]) # disable pat_gen, this is needed before it is re-enabled
trigger.write_list(addr=8, write_byte_list=[0]) # turn-off trigger, not really needed but good practice

