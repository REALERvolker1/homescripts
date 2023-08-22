#!/usr/bin/python3
import asyncio
from bleak import BleakScanner
from binascii import hexlify
from time import sleep

AIRPODS_MANUFACTURER = 76
AIRPODS_DATA_LENGTH = 54
UPDATE_INTERVAL = 2

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

def add_color_zsh_prompt(status):
    if status=='🚫':
        return status
    if status < 25:
        return f"%{{$fg[red]%}}{status}%{{$reset_color%}}"

    elif status < 50:
        return f"${{FG[202]}}{status}%{{$reset_color%}}"

    elif status < 75:
        return f"%{{$fg[yellow]%}}{status}%{{$reset_color%}}"
    else:
        return f"%{{$fg[green]%}}{status}%{{$reset_color%}}"

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

    res = "L:"+add_color_zsh_prompt(left_status)+' ' if left_status!='' else ''
    res += "R:"+add_color_zsh_prompt(right_status)+' ' if right_status!='' else ''
    res += "C:"+add_color_zsh_prompt(case_status)+' ' if case_status!='' else ''

    return res

async def main():
    with open("/tmp/airpods_battery.out", 'w+') as writer:
        while True:
            res=await get_data_from_bluetooth()
            writer.seek(0)
            if res is not None:
                writer.write(get_battery_from_data(res))
            writer.truncate()
            sleep(UPDATE_INTERVAL)

asyncio.run(main())
