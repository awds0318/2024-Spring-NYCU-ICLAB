import numpy as np
from numba import jit
import random
import sys
import copy


def hexx(n):
    return hex(n)[2:]


@jit(nopython=True)
def Lee_Algorithm(temp_map, step):

    for ii in range(64):
        for j in range(64):
            if temp_map[ii][j] == step:

                if ii >= 1 and temp_map[ii - 1][j] == 0:  # up
                    temp_map[ii - 1][j] = step + 1

                if ii <= 62 and temp_map[ii + 1][j] == 0:  # down
                    temp_map[ii + 1][j] = step + 1

                if j >= 1 and temp_map[ii][j - 1] == 0:  # left
                    temp_map[ii][j - 1] = step + 1

                if j <= 62 and temp_map[ii][j + 1] == 0:  # right
                    temp_map[ii][j + 1] = step + 1
    return


def solve(target_num, temp_map, source_x_y, sink_x_y):
    for i in range(64):
        for j in range(64):
            if temp_map[i][j] > 0:
                temp_map[i][j] = 10000

    for i in range(target_num):

        source_x, source_y = source_x_y[i]
        sink_x, sink_y = sink_x_y[i]

        # print("Forward, Target idx : ", i)
        # print('------------Forward------------')
        # print("source_x: {:2d}, source_y: {:2d}" .format(source_x, source_y))
        # print("sink_x  : {:2d}, sink_y  : {:2d}" .format(sink_x, sink_y))
        # print('-------------------------------')

        temp_map[source_y][source_x] = 1
        temp_map[sink_y][sink_x] = 0

        step = 1

        while step < 1001 and temp_map[sink_y][sink_x] == 0:
            Lee_Algorithm(temp_map, step)
            step += 1
            """
            for ii in range(64):
                for j in range(64):
                    if temp_map[ii][j] == step:
                        if ii >= 1 and temp_map[ii-1][j] == 0:   # up
                            temp_map[ii-1][j] = step + 1
                        if ii <= 62 and temp_map[ii+1][j] == 0 :  # down
                            temp_map[ii+1][j] = step + 1
                        if j >= 1 and temp_map[ii][j-1] == 0:   # left
                            temp_map[ii][j-1] = step + 1
                        if j <= 62 and temp_map[ii][j+1] == 0 :  # right
                            temp_map[ii][j+1] = step + 1
            """

        # print("End Forward")

        if step == 1001:
            # print("Fail!")
            return False
        else:
            step = temp_map[sink_y][sink_x] - 1
            cur_x = sink_x
            cur_y = sink_y

            # print("Retrace Start !")
            # print("-----------Retrace------------")
            # print("")

            while True:

                # print("step :", step)
                # print("cur_x: {}, cur_y: {}" .format(cur_x, cur_y))
                temp_map[cur_y][cur_x] = 10000

                if cur_x == source_x and cur_y == source_y:
                    break

                if cur_y <= 62 and temp_map[cur_y + 1][cur_x] == step:  # down
                    nxt_y = cur_y + 1
                    nxt_x = cur_x
                elif cur_y >= 1 and temp_map[cur_y - 1][cur_x] == step:  # up
                    nxt_y = cur_y - 1
                    nxt_x = cur_x

                elif cur_x <= 62 and temp_map[cur_y][cur_x + 1] == step:  # right
                    nxt_y = cur_y
                    nxt_x = cur_x + 1

                elif cur_x >= 1 and temp_map[cur_y][cur_x - 1] == step:  # left
                    nxt_y = cur_y
                    nxt_x = cur_x - 1

                cur_x = nxt_x
                cur_y = nxt_y

                step -= 1

                if step < 0:
                    sys.exit()

            # print("End Retrace")

        for i in range(64):
            for j in range(64):
                if temp_map[i][j] != 10000:
                    temp_map[i][j] = 0

    return True


def generate_map(num):
    temp_map = np.zeros((64, 64), dtype=int)
    target_arr = np.arange(1, 16)
    soucre_x_y = []
    sink_x_y = []
    if num < 11:
        max_width = 6
    else:
        max_width = 4

    np.random.shuffle(target_arr)

    for i in range(num):
        for j in range(2):  # source : 0,  sink : 1

            while True:
                width = random.randint(2, max_width)
                height = random.randint(2, max_width)

                temp_x_left_up = random.randint(2, 60)
                temp_y_left_up = random.randint(2, 60)

                temp_x_left_bot = temp_x_left_up
                temp_y_left_bot = temp_y_left_up + height - 1

                temp_x_right_up = temp_x_left_up + width - 1
                temp_y_right_up = temp_x_left_up

                temp_x_right_bot = temp_x_left_up + width - 1
                # temp_y_right_bot = temp_y_left_up + height - 1

                if (
                    not (temp_x_left_bot < 2 or temp_y_left_bot > 61 or temp_x_right_up < 2 or temp_y_right_up > 61 or temp_x_right_bot < 2 or temp_x_right_bot > 61)
                    and temp_map[temp_y_left_up : temp_y_left_bot + 1, temp_x_left_up : temp_x_right_bot + 1].sum() == 0
                ):

                    temp_map[temp_y_left_up : temp_y_left_bot + 1, temp_x_left_up : temp_x_right_bot + 1] = target_arr[i]

                    n = random.randint(1, 4)
                    if n == 1 or n == 3:
                        x = temp_x_left_up + random.randint(0, width - 1)
                        if n == 1:
                            y = temp_y_left_bot
                        else:
                            y = temp_y_left_up
                    else:
                        y = temp_y_left_up + random.randint(0, height - 1)
                        if n == 2:
                            x = temp_x_right_bot
                        else:
                            x = temp_x_left_bot

                    if j == 0:
                        soucre_x_y.append((x, y))
                    else:
                        sink_x_y.append((x, y))

                    break

    return temp_map, soucre_x_y, sink_x_y, target_arr


mapp = np.zeros((32, 64, 64), dtype=int)
source_array = []
sink_array = []
target_num_array = np.zeros((32,), dtype=int)
target_array = np.zeros((32, 15), dtype=int)


for k in range(32):
    target_num = random.randint(1, 15)
    target_num_array[k] = target_num
    print("Generate Frame: ", k)
    print("Target Num:", target_num)
    while True:
        temp_map, source_x_y, sink_x_y, target_arr = generate_map(target_num)

        target_array[k] = target_arr.copy()
        mapp[k] = temp_map.copy()

        # print("SUM:", np.sum(temp_map))
        valid = solve(target_num, temp_map, source_x_y, sink_x_y)
        if valid == True:
            source_array.append(copy.deepcopy(source_x_y))
            sink_array.append(copy.deepcopy(sink_x_y))
            break


# Write input.txt
fi = open("input.txt", "w")
fi.write("32\n")  # 32 Patterns
for i in range(32):
    fi.write(str(i) + " " + str(target_num_array[i]) + "\n")
    for j in range(target_num_array[i]):
        fi.write(str(target_array[i][j]) + "\n")
        fi.write(str(source_array[i][j][0]) + " " + str(source_array[i][j][1]) + "\n")
        fi.write(str(sink_array[i][j][0]) + " " + str(sink_array[i][j][1]) + "\n")

fi.close()

# Write location map
fo = open("dram.dat", "w")
for i in range(32):
    for j in range(64):
        for k in range(8):  # 32 bits represent 8 elements
            addr = "@" + hexx(65536 + 2048 * i + 32 * j + 4 * k)
            data = (
                hexx(mapp[i][j][8 * k + 1])
                + hexx(mapp[i][j][8 * k + 0])
                + " "
                + hexx(mapp[i][j][8 * k + 3])
                + hexx(mapp[i][j][8 * k + 2])
                + " "
                + hexx(mapp[i][j][8 * k + 5])
                + hexx(mapp[i][j][8 * k + 4])
                + " "
                + hexx(mapp[i][j][8 * k + 7])
                + hexx(mapp[i][j][8 * k + 6])
            )

            fo.write(addr)
            fo.write("\n")
            fo.write(data)
            fo.write("\n")


# Write weight
for i in range(32):
    for j in range(64):
        for k in range(8):  # 32 bits represent 8 elements
            addr = "@" + hexx(65536 * 2 + 2048 * i + 32 * j + 4 * k)
            data = (
                hexx(random.randint(1, 15))
                + hexx(random.randint(1, 15))
                + " "
                + hexx(random.randint(1, 15))
                + hexx(random.randint(1, 15))
                + " "
                + hexx(random.randint(1, 15))
                + hexx(random.randint(1, 15))
                + " "
                + hexx(random.randint(1, 15))
                + hexx(random.randint(1, 15))
            )

            fo.write(addr)
            fo.write("\n")
            fo.write(data)
            fo.write("\n")
fo.close()
