print("Enter the number of CPU cores to use in bitstream generation:")

input1 = int(raw_input())

f = open('num_cores.txt', 'w')

f.write(str(input1)+'\n')

f.close()
