import math
import random
import numpy as np

# pattern number
pat_num = 100


def dec2hex(b):
    return hex(int(b))[2:]


def hex2dec(b):
    return int(b, 16)


def generate_input():
    f = open("input.txt", "w")
    f.write(f"{pat_num}")
    f.write("\n")

    for i in range(pat_num):
        # Img
        for i in range(72):
            Img = random.uniform(0, 255)
            f.write(dec2hex(Img))
            f.write(" ")

        # Kernel
        for i in range(9):
            kernel = random.uniform(0, 255)
            f.write(dec2hex(kernel))
            f.write(" ")

        # Weight
        for i in range(4):
            weight = random.uniform(0, 255)
            f.write(dec2hex(weight))
            f.write(" ")

        f.write("\n")


def generate_output():
    f = open("input.txt", "r")
    fo = open("output.txt", "w")

    fo.write(f"{pat_num}")
    fo.write("\n")

    text = []

    for line in f:
        text.append(line.split(" "))
    # print(text)

    # Img : 6x6
    Img1 = np.zeros((6, 6))
    Img2 = np.zeros((6, 6))

    # kernel : 3x3
    Kernel = np.zeros((3, 3))

    # weight : 2x2
    Weight = np.zeros((2, 2))

    # for i in range(1, 2):
    for i in range(1, pat_num + 1):
        array = text[i]

        for a in range(6):
            for b in range(6):
                Img1[a][b] = hex2dec(array[a * 6 + b])

        for a in range(6):
            for b in range(6):
                Img2[a][b] = hex2dec(array[36 + a * 6 + b])

        for a in range(3):
            for b in range(3):
                Kernel[a][b] = hex2dec(array[72 + a * 3 + b])

        for a in range(2):
            for b in range(2):
                Weight[a][b] = hex2dec(array[81 + a * 2 + b])

        # print(text[i])
        # print(Img1)
        # print(Img2)
        # print(Kernel)
        # print(Weight)
        # --------------------------------------------------------------------

        # convolution
        feature1 = np.zeros((4, 4))
        feature2 = np.zeros((4, 4))
        for m in range(4):
            for n in range(4):
                for i in range(3):
                    for j in range(3):
                        feature1[m][n] += Img1[m + i][n + j] * Kernel[i][j]
                        feature2[m][n] += Img2[m + i][n + j] * Kernel[i][j]

        # print("before quantization: ", feature1)
        # print("before quantization: ", feature2)

        for m in range(4):
            for n in range(4):
                feature1[m][n] = math.floor(feature1[m][n] / 2295)
                feature2[m][n] = math.floor(feature2[m][n] / 2295)

        # print("after quantization: ", feature1)
        # print("after quantization: ", feature2)

        # max pooling
        max_pool1 = feature1.reshape(2, 2, 2, 2).max(axis=(1, 3))
        max_pool2 = feature2.reshape(2, 2, 2, 2).max(axis=(1, 3))
        # print(max_pool1)
        # print(max_pool2)

        # fully connect
        fc1 = np.zeros((2, 2))
        fc2 = np.zeros((2, 2))
        for i in range(2):
            for j in range(2):
                for k in range(2):
                    fc1[i][j] += max_pool1[i][k] * Weight[k][j]
                    fc2[i][j] += max_pool2[i][k] * Weight[k][j]

        # print("fc1 before quantization: ", fc1)
        # print("fc2 before quantization: ", fc2)

        for m in range(2):
            for n in range(2):
                fc1[m][n] = math.floor(fc1[m][n] / 510)
                fc2[m][n] = math.floor(fc2[m][n] / 510)

        # print("fc1 after quantization: ", fc1)
        # print("fc2 after quantization: ", fc2)

        flatten1 = []
        flatten2 = []
        for row in fc1:
            flatten1.extend(row)
        for row in fc2:
            flatten2.extend(row)

        # print(flatten1)
        # print(flatten2)

        # L1 distance
        L1_distance = abs(flatten1[0] - flatten2[0]) + abs(flatten1[1] - flatten2[1]) + abs(flatten1[2] - flatten2[2]) + abs(flatten1[3] - flatten2[3])

        # print(L1_distance)

        # activate function
        if L1_distance < 16:
            output = 0
        else:
            output = L1_distance
        # print(output)

        fo.write(dec2hex(output))

        fo.write("\n")


if __name__ == "__main__":
    generate_input()
    generate_output()
    # for a in range(36):
    #     print(f"always @(posedge CG_input_clk[{a}]) if(in_cnt == {a} || in_cnt == {a + 36}) img1_reg[{math.floor(a / 6)}][{a % 6}] <= img;")
    # for a in range(36, 72):
    #     print(f"always @(posedge CG_input_clk[{a}]) if(in_cnt == {a}) img2_reg[{math.floor((a-36) / 6)}][{(a-36) % 6}] <= img;")