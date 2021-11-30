using CSV
using DataFrames
print("Reading image file......")
df_img = DataFrame(CSV.File("test_img_2.csv"))
#df_img = DataFrame(CSV.File("test_img_3.csv"))
println("Complete")

using Tester
jtag = JTAG()

# df_img[j,i+2]
#df_img: 28,29

global arr = UInt8[]
global addr = 204000
global counter = 0

println("Writing image file......")
for j in 1:size(df_img,1)
	for i in 2:size(df_img,2)
		append!(arr, df_img[j,i])#append!(arr,parse(UInt8,df_img[j,i],base=10))
		global counter += 1
	end
end
write(jtag,addr,arr)
global arr = []
print("Write completed. Image address starts from ")
print(addr)
print(" to ")
println((addr + counter - 1))
