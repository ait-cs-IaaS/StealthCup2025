import socket
 
# Modbus Configuration
MODBUS_HOST = "10.0.1.74"  # Target Modbus device IP
MODBUS_PORT = 420          # Modbus UDP port
REGISTER_ADDRESS = 5       # Coil address
UNIT_ID = 1                # Modbus Unit ID
 
def write_modbus_coil(value):
    """Sends a Modbus-UDP packet to write a single coil (1=True, 0=False)"""
    # Define Modbus-TCP Write Single Coil Request (0x05)
    coil_high = 0xFF if value == 1 else 0x00
    coil_low = 0x00  # Always 0x00 for False
 
    request = bytes([
        0x00, 0x01,  # Transaction ID
        0x00, 0x00,  # Protocol ID
        0x00, 0x06,  # Length
        UNIT_ID,     # Unit ID
        0x05,        # Function Code: Write Single Coil (0x05)
        0x00, REGISTER_ADDRESS,  # Coil Address (High Byte, Low Byte)
        coil_high, coil_low      # Value (0xFF00 = ON, 0x0000 = OFF)
    ])
 
    # Send Modbus Request via UDP
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.sendto(request, (MODBUS_HOST, MODBUS_PORT))
 
# Example: Write 1 (True) to the coil
write_modbus_coil(1)