# tang_nano-trigger_uart
This is a re-write of my previous trigger project. This time Tang Nano and Tang Nano 9k are the target hardware boards and the USB UART is used to configure and enable triggering.<p>
**Tang Nano connections:**

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/tang_nano_trigger.jpg)

**Tang Nano 9k connections:**
  
![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/tang_nano_9K_trigger.png)
  
I included my pattern generator and block ram designs, which aid in validating the trigger functions. If you have an inexpensive logic analyzer you can view all the stimulus waveforms and the resulting triggers. The pins **trigger_in** and **pat_gen_out[0]** need to be connected.<p>

I support all trigger types listed here: https://www.tiepie.com/en/fut/pulse-width-trigger <p>

***  
  
**Type 0 Positive Edge** (no count durations, just trigger on the edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_0_positive_edge.png)
  
**Type 0 Negative Edge** (no count durations, just trigger on the edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_0_negative_edge.png)

***
  
**Type 1 Positive Edge** (trigger on pulses shorter than count1)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_1_positive_edge.png)

**Type 1 Negative Edge** (trigger on pulses shorter than count1)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_1_negative_edge.png)

***
  
**Type 2 Positive Edge** (trigger on positive pulses larger than count1 on the falling edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_2_positive_edge.png)
  
**Type 2 Positive No Edge** (trigger on positive pulses larger than count1, immediately before the falling edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_2_positive_no_edge.png)
  
**Type 2 Negative Edge** (trigger on negative pulses larger than count1 on the rising edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_2_negative_edge.png)

**Type 2 Negative No Edge** (trigger on negative pulses larger than count1, immediately before the rising edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_2_negative_no_edge.png)
  
***
  
**Type 3 Positive Edge** (trigger on positive pulses larger than count1 **AND** less than count2, on the falling edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_3_positive_edge.png)
  
**Type 3 Negative Edge** (trigger on negative pulses larger than count1 **AND** less than count2, on the rising edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_3_negative_edge.png)
  
***

**Type 4 Positive Edge** (trigger on positive pulses larger than count1 **OR** less than count2, on the falling edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_4_positive_edge.png)
  
**Type 4 Positive No Edge** (trigger on positive pulses larger than count1 **OR** less than count2, immediately before falling edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_4_positive_edge.png)

**Type 4 Negative Edge** (trigger on negative pulses larger than count1 **OR** less than count2, on the rising edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_4_negative_edge.png)
  
**Type 4 Negative No Edge** (trigger on negative pulses larger than count1 **OR** less than count2, immediately before the rising edge)

![picture](https://github.com/charkster/tang_nano-trigger_uart/blob/main/images/trigger_pulseview_type_4_negative_no_edge.png)
  
***
  
That's it. 
