import machine, time

while True:
    machine.Pin(25, machine.Pin.OUT).on()
    time.sleep(0.5)
    machine.Pin(25, machine.Pin.OUT).off()
    time.sleep(0.5)