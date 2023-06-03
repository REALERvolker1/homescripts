#!/usr/bin/python3
import os
import random

directory_path = "/usr/share/games/fortune"
max_length = 4

fortunes = []

def searchfile(filename):
    #print(filename)
    filepath = os.path.join(directory_path, filename)

    f = open(filepath, "r")
    contents = f.read()
    f.close()

    return_values = []
    content_list = contents.split("%")

    for i in content_list:
        i_list = []
        for j in i.split("\n"):
            if j == '':
                continue
            i_list.append(j)

        i_string = "\n".join(i_list)

        if len(i_list) < max_length and i_string != "":
            return_values.append(i_string)


    return return_values


def main():
    for filename in os.listdir(directory_path):
        if not "." in filename:
            try:
                search_results = searchfile(filename)
            except:
                continue
                #print(f"Could not read file {filename}")
            fortunes.extend(search_results)

    print(fortunes[random.randint(0, len(fortunes))])

main()

#print(searchfile("art"))
