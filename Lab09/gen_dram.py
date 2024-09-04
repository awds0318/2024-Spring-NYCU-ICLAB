import random


def dec2hex(d, fill):
    return hex(int(d))[2:].zfill(fill)


def date():
    month = random.randint(1, 12)
    if month == 1 or month == 3 or month == 5 or month == 7 or month == 8 or month == 10 or month == 12:
        day = random.randint(1, 31)
    elif month == 4 or month == 6 or month == 9 or month == 11:
        day = random.randint(1, 30)
    else:
        day = random.randint(1, 28)
    return month, day


def volume():
    return random.randint(0, 255)


def main():
    f = open("dram.dat", "w")

    for i in range(256):
        month, day = date()

        f.write(f"@10{dec2hex(i * 8, 3)}")  # @10008
        f.write("\n")

        # 11 19 52 78
        f.write(f"{dec2hex(day, 2)} ")
        f.write(f"{dec2hex(volume(), 2)} {dec2hex(volume(), 2)} {dec2hex(volume(), 2)}")
        f.write("\n")

        f.write(f"@10{dec2hex(i * 8 + 4, 3)}")  # @1000C
        f.write("\n")

        # 0b 2d 58 c2
        f.write(f"{dec2hex(month, 2)} ")
        f.write(f"{dec2hex(volume(), 2)} {dec2hex(volume(), 2)} {dec2hex(volume(), 2)}")
        f.write("\n")

    f.close()


if __name__ == "__main__":
    main()
