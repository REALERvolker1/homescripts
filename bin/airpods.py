#!/usr/bin/python3
# script originally from https://github.com/A-delta/zsh-airpods-battery
# modified to death by vlk

import asyncio
from bleak import BleakScanner
from binascii import hexlify
from time import sleep
from sys import argv
from os import environ

AIRPODS_MANUFACTURER = 76
AIRPODS_DATA_LENGTH = 54
UPDATE_INTERVAL = 2

OUTPUT_METHOD = "stdout"
OUTPUT_TYPE = "string"
for arg in argv:
    if arg == argv[0]:
        continue
    match arg:
        case "--stdout" :
            OUTPUT_METHOD = "stdout"
        case "--tmpfile" :
            OUTPUT_METHOD = "tempfile"
        case "--json":
            OUTPUT_TYPE = "json"
        case "--string":
            OUTPUT_TYPE = "string"
        case "--single-highest":
            OUTPUT_TYPE = "single-highest"
        case "--single-lowest":
            OUTPUT_TYPE = "single-lowest"
        case "--zsh-prompt":
            OUTPUT_TYPE = "zsh-prompt"
        case _:
            print("\n".join([
                    "airpods.py",
                    "Continuously monitors your airpods battery level",
                    "Due to Apple being stupid, it only works in intervals of 5",
                    "",
                    "Possible output methods",
                    "--tmpfile       Output to a tempfile",
                    "    tempfile path is $XDG_RUNTIME_DIR/airpods_battery.out",
                    "    If $XDG_RUNTIME_DIR is not set, it falls back to /tmp",
                    "    This can be overridden with the environment variable $AIRPODS_TMPFILE",
                    "",
                    "--stdout        Output directly to stdout (Default)",
                    "    This is useful if you want to use it as a statusbar module",
                    "",
                    "Possible output types",
                    "--json            Print output as a json string",
                    "    `{\"left\": 95, \"left_charging\": false, \"right\": 95, \"right_charging\": false}`",
                    "",
                    "--string          Print output as a human-readable string (Default)",
                    "    `L: 95, R: 95`",
                    "",
                    "--single-highest  Print a single integer, the highest out of either left or right",
                    "--single-lowest   Print a single integer, the lowest out of either left or right",
                    "    `95`"
                    ])
            )
            exit(1)


async def get_data_from_bluetooth():
    discovered_devices_and_advertisement_data = await BleakScanner.discover(return_adv=True)
    for key, dev_and_adv_dat in discovered_devices_and_advertisement_data.items():
        device = dev_and_adv_dat[0]
        adv_dat = dev_and_adv_dat[1]
        if AIRPODS_MANUFACTURER in adv_dat.manufacturer_data.keys():
            hexa_data = hexlify(adv_dat.manufacturer_data[AIRPODS_MANUFACTURER])
            if len(hexa_data)==AIRPODS_DATA_LENGTH and int(chr(hexa_data[1]), 16) == 7:
                return hexa_data
    return None

def is_flipped(raw):
    return (int("" + chr(raw[10]), 16) & 0x02) == 0

def get_battery_from_data(data_hexa):
    flip: bool = is_flipped(data_hexa)

    # 0-10 : battery, 15 : disconnected
    status_tmp = int("" + chr(data_hexa[12 if flip else 13]), 16)
    left_status = (100 if status_tmp == 10 else (status_tmp * 10 + 5 if status_tmp <= 10 else ''))


    status_tmp = int("" + chr(data_hexa[13 if flip else 12]), 16)
    right_status = (100 if status_tmp == 10 else (status_tmp * 10 + 5 if status_tmp <= 10 else ''))

    status_tmp = int("" + chr(data_hexa[15]), 16)
    case_status = (100 if status_tmp == 10 else (status_tmp  * 10 + 5 if status_tmp <= 10 else ''))

    charging_status = int("" + chr(data_hexa[14]), 16)
    charging_left:bool = (charging_status & (0b00000010 if flip else 0b00000001)) != 0
    charging_right:bool = (charging_status & (0b00000001 if flip else 0b00000010)) != 0
    charging_case:bool = (charging_status & 0b00000100) != 0

    res = []
    return_str = ""

    left_active = (left_status != '')
    right_active = (right_status != '')
    case_active = (case_status != '')
    match OUTPUT_TYPE:
        case "json":
            if left_active:
                res.append(f'"left": {left_status}')
                res.append(f'"left_charging": {str(charging_left).lower()}')
            if right_active:
                res.append(f'"right": {right_status}')
                res.append(f'"right_charging": {str(charging_right).lower()}')
            if case_active:
                res.append(f'"case": {case_status}')
                res.append(f'"case_charging": {str(charging_case).lower()}')

            return_str = "{" + ", ".join(res) + "}"

        case "string":
            if left_active:
                tmpstr = "L: "
                if charging_left:
                    tmpstr += "(Charging) "
                tmpstr += str(left_status)
                res.append(tmpstr)
            if right_active:
                tmpstr = "R: "
                if charging_right:
                    tmpstr += "(Charging) "
                tmpstr += str(right_status)
                res.append(tmpstr)
            if case_active:
                tmpstr = "C: "
                if charging_case:
                    tmpstr += "(Charging) "
                tmpstr += str(case_status)
                res.append(tmpstr)

            return_str = ", ".join(res)

        case "single-highest":
            if left_active and right_active:
                if left_status >= right_status:
                    return_str = left_status
                else:
                    return_str = right_status
            elif left_active:
                return_str = left_status
            elif right_active:
                return_str = right_status
            elif case_active:
                return_str = case_status

        case "single-lowest":
            if left_active and right_active:
                if left_status >= right_status:
                    return_str = right_status
                else:
                    return_str = left_status
            elif left_active:
                return_str = left_status
            elif right_active:
                return_str = right_status
            elif case_active:
                return_str = case_status

    return return_str

async def main():
    if OUTPUT_METHOD == "tempfile":
        tempfile = environ.get("AIRPODS_TMPFILE")
        if tempfile == None:
            runtime_dir = environ.get("XDG_RUNTIME_DIR")
            if runtime_dir == None:
                runtime_dir = "/tmp"
            tempfile = f"{runtime_dir}/airpods_battery.out"
        with open(tempfile, 'w+') as writer:
            while True:
                res=await get_data_from_bluetooth()
                writer.seek(0)
                if res is not None:
                    writer.write(get_battery_from_data(res))
                writer.truncate()
                sleep(UPDATE_INTERVAL)

    elif OUTPUT_METHOD == "stdout":
        while True:
            res=await get_data_from_bluetooth()
            if res is not None:
                print(get_battery_from_data(res))
            sleep(UPDATE_INTERVAL)

asyncio.run(main())
