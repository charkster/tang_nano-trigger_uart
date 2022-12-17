import serial
import time

class scarf_uart_slave:
	
	# Constructor
	def __init__(self, slave_id=0x00, num_addr_bytes=1, port=serial.Serial(port='/dev/ttyUSB1', baudrate=1000000, bytesize=8, parity='N', stopbits=1, timeout=0.001), debug=False):
		self.slave_id         = slave_id
		self.num_addr_bytes   = num_addr_bytes
		self.port             = port
		self.read_buffer_max  = 31 - self.num_addr_bytes # this is a tang_nano limitation
		self.write_buffer_max = 60 - self.num_addr_bytes # this is a tang_nano limitation
		self.debug            = debug
		
	# this routine allows "num_bytes" to be larger than the self.read_buffer_max
	def read_list(self, addr=0x00, num_bytes=1):
		if (self.debug == True):
			print("Called read")
		if (num_bytes == 0):
			print("Error: num_bytes must be larger than zero")
			return []
		else:
			self.port.reset_input_buffer()
			self.port.reset_output_buffer()
			byte0 = (self.slave_id + 0x80) & 0xFF
			remaining_bytes = num_bytes
			read_list = []
			address = addr - self.read_buffer_max # expecting to add self.read_buffer_max
			while (remaining_bytes > 0):
				if (remaining_bytes >= self.read_buffer_max):
					step_size = self.read_buffer_max
					remaining_bytes = remaining_bytes - self.read_buffer_max
				else:
					step_size = remaining_bytes
					remaining_bytes = 0
				address = address + self.read_buffer_max
				addr_byte_list = []
				for addr_byte_num in range(self.num_addr_bytes):
					addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
				self.port.write(bytearray([byte0] + addr_byte_list + [step_size]))
				time.sleep(0.1)
				tmp_read_list = list(self.port.read(step_size + self.num_addr_bytes + 1))
				read_list = tmp_read_list[-step_size:]
				del tmp_read_list[0] # first byte is echoed slave_id
			if (self.debug == True):
				address = addr
				for read_byte in read_list:
					print("Address 0x{:02x} Read data 0x{:02x}".format(address,read_byte))
					address += 1
			return read_list
	
	# this routine allows "write_byte_list" to be larger than the self.write_buffer_max
	def write_list(self, addr=0x00, write_byte_list=[]):
		self.port.reset_input_buffer()
		self.port.reset_output_buffer()
		byte0 = self.slave_id & 0xFF
		remaining_bytes = len(write_byte_list)
		address = addr - self.write_buffer_max # expecting to add self.write_buffer_max
		while (remaining_bytes > 0):
			if (remaining_bytes >= self.write_buffer_max):
				step_size = self.write_buffer_max
				remaining_bytes = remaining_bytes - self.write_buffer_max
			else:
				step_size = remaining_bytes
				remaining_bytes = 0
			address = address + self.write_buffer_max
			addr_byte_list = []
			for addr_byte_num in range(self.num_addr_bytes):
				addr_byte_list.insert(0, address >> (8*addr_byte_num) & 0xFF )
			self.port.write(bytearray([byte0] + addr_byte_list + write_byte_list[address-addr:address+step_size]))
			time.sleep(0.1)
		if (self.debug == True):
			print("Called write_bytes")
			address = addr
			for write_byte in write_byte_list:
				print("Wrote address 0x{:02x} data 0x{:02x}".format(address,write_byte))
				address += 1
		return 1
	
	# Two bytes are returned, when a read of 1 byte is specified. An echo of the slave_id and RNW bit, and the actual read byte
	# The slave_id is kept and the actual read is ignored. The most significant bit is the RNW, and this is removed to just return the slave_id
	def read_id(self):
		self.port.reset_input_buffer()
		self.port.reset_output_buffer()
		byte0 = (self.slave_id + 0x80)
		self.port.write(bytearray([byte0] + [0x00, 0x01]))
		time.sleep(0.1)
		slave_id_list = list(self.port.read(2))
		slave_id = slave_id_list[0] - 0x80
		if (self.debug == True):
			print("Slave ID is 0x{:02x}".format(slave_id))
		return slave_id
