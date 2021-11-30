# cd("E:\\WORK1\\ee297\\de10lite-hdl-master\\de10lite-hdl-master\\projects\\sdram_tester\\julia")
# activate env 
# read file (some simple hex number)
# read file (the whole file)
# loop toassign address and write to sdram

# print("Test: read file\n")

# to run this file: include("write_w.jl") 
# type import Pkg; Pkg.add("CSV"); Pkg.add("DataFrames"); Pkg.add("ProgressMeter") # this line needs only once, it will install the package


using CSV
using DataFrames
print("Reading weight1......")
df = DataFrame(CSV.File("weight1_hex.csv"))
println("Complete")

using Tester
using Sockets
using ProgressMeter
jtag = JTAG()

counter = 0

# println("Packaging weight1....")
"""
* `writesize_max = 2^14` - The maximum number of bytes to write in any single 
    write action. 16384
* `writesize_min = 2` - The minimum number of bytes to write in any single write
    action.
# size(df, 1) = 784
# size(df, 2) = 65
"""
# Function to calculate the address of weights by inputing row and column
function addr_cal(row, col)		#784,65 weight1
	4*(col-2)+256*(row-1)
end
function addr_cal2(row, col)		#64,11 weight2
	4*(col-2)+40*(row-1)+addr_cal(size(df,1),size(df,2)+4)
end

global byte_length = 16000
global addr = 0
global arr = []
empty!(arr)
@showprogress "Writing weight1 into FPGA......" for j in 1:size(df,1)
	for i in 2:size(df,2)
		str = df[j,i]
		arr_temp = [parse(UInt8, str[7:8],base=16),parse(UInt8, str[5:6],base=16),
				parse(UInt8, str[3:4],base=16),parse(UInt8, str[1:2],base=16)]				#little endian
		append!(arr,arr_temp)
		if(size(arr,1) >= byte_length) 
			#println(arr)
			#println(addr)
			write(jtag,addr,arr)
			global addr += size(arr,1)
			empty!(arr)
		end
		if(j==size(df,1) && i == size(df,2)) 
			write(jtag,addr,arr)
			global addr += size(arr,1)
		end
	end
	#sleep(0.0003)
end
# check a data from csv file: df[row, column]
# address of df[j,i] = 4*(i-2)+256*(j-1)   --weight 1
print("Write weight1 completed, total addresses used: ")
println(addr)

############################# bias1 #########################################
print("Reading bias1......")
df = DataFrame(CSV.File("bias1_hex.csv"))
println("Complete")

global arr = []
global addr = 200704
empty!(arr)
println("Writing bias1 into FPGA......")
for i in 1:size(df,1)
	str = df[i,2]
	arr_temp = [parse(UInt8, str[7:8],base=16),parse(UInt8, str[5:6],base=16),
				parse(UInt8, str[3:4],base=16),parse(UInt8, str[1:2],base=16)]				#little endian
	append!(arr,arr_temp)
end
write(jtag,addr,arr)
empty!(arr)

#w2
# size(df2, 1) = 64
# size(df2, 2) = 11
print("Reading weight2......")
df2 = DataFrame(CSV.File("weight2_hex.csv"))
println("Complete")

global addr = 200960
global arr = []
empty!(arr)
@showprogress "Writing weight2 into FPGA......" for j in 1:size(df2,1)
	for i in 2:size(df2,2)
		str = df2[j,i]
		arr_temp = [parse(UInt8, str[7:8],base=16),parse(UInt8, str[5:6],base=16),
				parse(UInt8, str[3:4],base=16),parse(UInt8, str[1:2],base=16)]				#little endian
		append!(arr,arr_temp)
		if(size(arr,1) >= byte_length) 
			#println(arr)
			#println(addr)
			write(jtag,addr,arr)
			global addr += size(arr,1)
			empty!(arr)
		end
		if(j==size(df2,1) && i == size(df2,2)) 
			write(jtag,addr,arr)
			global addr += size(arr,1)
		end
	end
	#sleep(0.0003)
end
print("Write weight2 completed, total addresses used: ")
println(addr)


############################# bias2 #########################################

print("Reading bias2......")
df2 = DataFrame(CSV.File("bias2_hex.csv"))
println("Complete")

global arr = []
global addr = 203520

for i in 1:size(df2,1)
	str = df2[i,2]
	arr_temp = [parse(UInt8, str[7:8],base=16),parse(UInt8, str[5:6],base=16),
				parse(UInt8, str[3:4],base=16),parse(UInt8, str[1:2],base=16)]				#little endian
	append!(arr,arr_temp)
end

write(jtag,addr,arr)
empty!(arr)


println("-------------------------")
#println("Weight1 address: 0 to ", addr_cal(size(df,1),size(df,2))+3)
#println("Weight2 address: ", addr_cal(size(df,1),size(df,2))+4," to ", addr)

