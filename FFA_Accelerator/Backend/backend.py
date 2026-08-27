import serial
import struct
import time
from psrqpy import QueryATNF

def read_period_from_serial(port, baudrate=9600):
    try:
        with serial.Serial(port, baudrate, timeout=10) as ser:
            print(f"Listening on {port}...")
            # Read start byte (0xAA) to synchronize with UART frame
            start_byte = ser.read(1)
            if start_byte != b'\xAA':
                print(" Waiting for start byte...")
                return None
            # Read 4 bytes of period data (little-endian)
            period_bytes = ser.read(4)
            if len(period_bytes) == 4:
                period_microseconds = struct.unpack('<I', period_bytes)[0]
                print(f" Received raw value: {period_microseconds}")
                return period_microseconds
            else:
                print(" Timed out.")
                return None
    except serial.SerialException as e:
        print(f" Error: {e}")
        return None

def find_pulsar_in_catalogue(period_ms, tolerance=0.005):
    period_seconds = period_ms / 1000.0
    print(f"\nSearching ATNF Catalogue for period: {period_seconds:.6f} s...")
    min_p = period_seconds * (1 - tolerance)
    max_p = period_seconds * (1 + tolerance)
    condition = f"P0 > {min_p} && P0 < {max_p}"
    try:
        query = QueryATNF(params=['PSRJ', 'P0', 'NAME'], condition=condition)
        if query.Npsr > 0:
            print(f" Success! Found {query.Npsr} match(es):")
            for pulsar in query.psr_all:
                print(f"  -> {pulsar.NAME} ({pulsar.PSRJ}) | Known Period: {pulsar.P0} s")
        else:
            print("-- No matching pulsar found. New candidate!")
    except Exception as e:
        print(f" DB Query Error: {e}")

if __name__ == '__main__':
    # !!! IMPORTANT: CHANGE THIS to your FPGA's serial port name !!!
    SERIAL_PORT = '/dev/tty.usbserial-1410' 

    while True:
        received_period_us = read_period_from_serial(port=SERIAL_PORT)
        if received_period_us is not None:
            period_milliseconds = received_period_us / 1000.0
            find_pulsar_in_catalogue(period_milliseconds)
        print("\n" + "-"*50)
        time.sleep(2)