import math
import random
import struct
import numpy as np

# pattern number
pat_num = 100
mode = ["0", "1"]
matrix_size_list = [0, 1, 2]


def sign_dec2bin(x, bits=8):
    n = (1 << bits) - 1
    x2 = n & x
    if x < 0:
        return f"{x2:#{bits+2}b}"
    else:
        return f"{x2:#0{bits+2}b}"


def signed_bin2dec(bin_str: str) -> int:
    bin_str = bin_str.strip()
    if bin_str[0] == "0":
        return int(bin_str, base=2)
    elif bin_str[0] == "1":
        a = int(bin_str, base=2)
        bin_str = bin_str.replace("_", "")
        return a - 2 ** len(bin_str)


def bin2hex(b):
    return hex(int(b, 2))[2:]


def hex2bin(b):
    return bin(int(b, 16))[2:]


def generate_input():
    f = open("input.txt", "w")
    f.write(f"{pat_num}")
    f.write("\n")

    for i in range(pat_num):
        # matrix_size
        matrix_size = random.choice(matrix_size_list)
        f.write(f"{matrix_size}")
        f.write(" ")

        # ---------------- matrix ----------------
        # image
        for i in range(16 * ((2 ** (matrix_size + 3)) ** 2)):
            img = random.randint(-128, 127)
            Img_binary = sign_dec2bin(img)[2:]
            f.write(Img_binary)
            f.write(" ")
        # kernel
        for i in range(16 * 5 * 5):  # 16 x 5 x 5
            kernel = random.randint(-128, 127)
            kernel_binary = sign_dec2bin(kernel)[2:]
            f.write(kernel_binary)
            f.write(" ")

        for i in range(16):
            # --------------- matrix_idx -------------
            image_index = random.randint(0, 15)
            f.write(hex(image_index)[2:])
            f.write(" ")

            kernel_index = random.randint(0, 15)
            f.write(hex(kernel_index)[2:])

            f.write(" ")
            # --------------- mode -------------
            f.write(random.choice(mode))
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

    for i in range(1, pat_num + 1):
        array = text[i]
        matrix_size = array[0]
        # print(matrix_size)

        matrix_size = int(matrix_size)
        size = 2 ** (matrix_size + 3)
        kernel_start_index = 16 * (size**2) + 1

        # Img
        Img = np.zeros((16, size, size))
        # kernel
        Kernel = np.zeros((16, 5, 5))

        for c in range(16):
            for a in range(size):
                for b in range(size):
                    Img[c][a][b] = signed_bin2dec(array[1 + a * size + b + c * (size**2)])

        for c in range(16):
            for a in range(5):
                for b in range(5):
                    Kernel[c][a][b] = signed_bin2dec(array[kernel_start_index + a * 5 + b + c * 25])  # 1025 = 16 x 8 x 8 + 1

        # print(Kernel[15])
        # print(Img[13])
        # --------------------------------------------------------------------
        image_index_start = kernel_start_index + 400
        for i in range(1):
            a = i * 3
            image_index = int(array[image_index_start + a], 16)  # `1025 + 400`
            Kernel_index = int(array[image_index_start + 1 + a], 16)
            mode = array[image_index_start + 2 + a]

            # Img
            img = np.zeros((size, size))
            # kernel
            ker = np.zeros((5, 5))
            # print(image_index)
            img = Img[image_index]
            ker = Kernel[Kernel_index]
            # print(img)
            # print(ker)
            if mode == "0":
                # convolution
                feature = np.zeros((size - 4, size - 4))
                for m in range(size - 4):
                    for n in range(size - 4):
                        for i in range(5):
                            for j in range(5):
                                feature[m][n] += img[m + i][n + j] * ker[i][j]

                # print("feature")
                # print(feature)
                max_pool = feature.reshape(((size - 4) // 2), 2, ((size - 4) // 2), 2).max(axis=(1, 3))
                # print("max_pool")
                # print(max_pool)
                list = []
                for m in max_pool:
                    for n in m:
                        o = sign_dec2bin(int(n), 20)[2:]
                        list.append(o)

                for li in list:
                    li = bin2hex(li)
                    fo.write(f"{li}")
                    fo.write(" ")

                # print(list)

                fo.write("\n")

                # print(o)
            if mode == "1":
                img_padding = np.pad(img, ((4, 4), (4, 4)), "constant")
                # print(img_padding)
                ker_revrse = np.zeros((5, 5))
                for i in range(5):
                    for j in range(5):
                        ker_revrse[i][j] = ker[4 - i][4 - j]

                feature = np.zeros((size + 4, size + 4))
                for m in range(size + 4):
                    for n in range(size + 4):
                        for i in range(5):
                            for j in range(5):
                                feature[m][n] += img_padding[m + i][n + j] * ker_revrse[i][j]
                # print("feature")
                # print(feature)
                # print(ker_revrse)
                # print(ker)

                list = []
                for m in feature:
                    for n in m:
                        o = sign_dec2bin(int(n), 20)[2:]
                        list.append(o)

                for li in list:
                    li = bin2hex(li)
                    fo.write(f"{li}")
                    fo.write(" ")

                # print(list)

                fo.write("\n")


if __name__ == "__main__":
    generate_input()
    generate_output()
