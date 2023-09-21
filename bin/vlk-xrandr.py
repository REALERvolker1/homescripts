#!/usr/bin/python3

class Monitor:
    is_primary = false
    def __init__(self, output, mode, refresh, pos, is_primary):
        self.output = output
        self.mode = mode
        self.pos = pos
        self.is_primary = is_primary

primary_monitor = Monitor("eDP-1", "1920x1080", 144, )
