import math
import random
import struct
import numpy as np

# pattern number
pat_num = 10000
opt = ["0", "1", "2", "3"]


def generate_value(a, b):
    value = random.uniform(a, b)
    sign = random.choice((-1, 1))
    value = value * sign
    return value


def float2bin(f):  # 0.08721975 --> 00111101101100101010000001000101 (IEEE754 32bits)
    return "{:032b}".format(struct.unpack(">I", struct.pack("!f", f))[0])


def bin2float(b):  # 00111101101100101010000001000101 -> 0.08721975
    return struct.unpack("!f", int(b, 2).to_bytes(4, byteorder="big"))[0]


def bin2hex(b):
    return hex(int(b, 2))[2:]


def hex2bin(b):
    return bin(int(b, 16))[2:]


def generate_input():
    f = open("input.txt", "w")
    f.write(f"{pat_num}")
    f.write("\n")

    for i in range(pat_num):
        # Opt
        f.write(random.choice(opt))
        f.write(" ")

        # Img
        for i in range(48):
            Img_float = generate_value(0.5, 255)
            Img_binary = float2bin(Img_float)
            f.write(bin2hex(Img_binary))
            f.write(" ")

        # Kernel
        for i in range(27):
            kernel_float = generate_value(0, 0.5)
            kernel_binary = float2bin(kernel_float)
            f.write(bin2hex(kernel_binary))
            f.write(" ")

        # Weight
        for i in range(4):
            weight_float = generate_value(0, 0.5)
            weight_binary = float2bin(weight_float)
            f.write(bin2hex(weight_binary))
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

    # Img : 4x4
    Img1_1 = np.zeros((4, 4))
    Img1_2 = np.zeros((4, 4))
    Img1_3 = np.zeros((4, 4))

    # kernel : 3x3
    Kernel1 = np.zeros((3, 3))
    Kernel2 = np.zeros((3, 3))
    Kernel3 = np.zeros((3, 3))

    # weight : 2x2
    Weight = np.zeros((2, 2))

    for i in range(1, pat_num + 1):
        array = text[i]
        Opt = array[0]

        for a in range(4):
            for b in range(4):
                Img1_1[a][b] = bin2float(hex2bin(array[1 + a * 4 + b]))

        for a in range(4):
            for b in range(4):
                Img1_2[a][b] = bin2float(hex2bin(array[17 + a * 4 + b]))

        for a in range(4):
            for b in range(4):
                Img1_3[a][b] = bin2float(hex2bin(array[33 + a * 4 + b]))

        for a in range(3):
            for b in range(3):
                Kernel1[a][b] = bin2float(hex2bin(array[49 + a * 3 + b]))

        for a in range(3):
            for b in range(3):
                Kernel2[a][b] = bin2float(hex2bin(array[58 + a * 3 + b]))

        for a in range(3):
            for b in range(3):
                Kernel3[a][b] = bin2float(hex2bin(array[67 + a * 3 + b]))

        for a in range(2):
            for b in range(2):
                Weight[a][b] = bin2float(hex2bin(array[76 + a * 2 + b]))

        # print(text[i])
        # print(Kernel1)
        # --------------------------------------------------------------------
        if Opt in ["0", "1"]:
            Img1_1_padding = np.pad(Img1_1, ((1, 1), (1, 1)), "constant")
            Img1_2_padding = np.pad(Img1_2, ((1, 1), (1, 1)), "constant")
            Img1_3_padding = np.pad(Img1_3, ((1, 1), (1, 1)), "constant")
        if Opt in ["2", "3"]:
            Img1_1_padding = np.pad(Img1_1, ((1, 1), (1, 1)), "edge")
            Img1_2_padding = np.pad(Img1_2, ((1, 1), (1, 1)), "edge")
            Img1_3_padding = np.pad(Img1_3, ((1, 1), (1, 1)), "edge")

        # print(Img1_1_padding)

        # convolution
        feature = np.zeros((4, 4))
        for m in range(4):
            for n in range(4):
                for i in range(3):
                    for j in range(3):
                        feature[m][n] += Img1_1_padding[m + i][n + j] * Kernel1[i][j] + Img1_2_padding[m + i][n + j] * Kernel2[i][j] + Img1_3_padding[m + i][n + j] * Kernel3[i][j]

        # print(feature)

        # max pooling
        max_pool = feature.reshape(2, 2, 2, 2).max(axis=(1, 3))
        # print(max_pool)

        # fully connect
        fc = np.zeros((2, 2))
        for i in range(2):
            for j in range(2):
                for k in range(2):
                    fc[i][j] += max_pool[i][k] * Weight[k][j]
        # print(Weight)
        # print(fc)

        flatten = []
        for row in fc:
            flatten.extend(row)
        # print(flatten)

        # normalization
        max_value = max(flatten)
        min_value = min(flatten)
        for i in range(4):
            flatten[i] = (flatten[i] - min_value) / (max_value - min_value)
        # print(flatten)

        # activate function
        output = [0, 0, 0, 0]
        for i in range(4):
            x = flatten[i]
            if Opt == "0":  # ReLu
                output[i] = max(0, x)
            if Opt == "1":  # Tanh
                output[i] = (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x))
            if Opt == "2":  # Sigmoid
                output[i] = 1 / (1 + math.exp(-x))
            if Opt == "3":  # soft plus
                output[i] = np.log((1 + math.exp(x)))

        # print(output)

        for o in output:
            fo.write(bin2hex(float2bin(o)))
            fo.write(" ")

        fo.write("\n")


if __name__ == "__main__":
    generate_input()
    generate_output()
