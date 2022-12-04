

using BitSAD
using bp_decode

# pcm = #not a param for dec

  1 2 3 4 5 6 7 8 9 10 11 12 13
1 1 1               1
2   1 1                1
3       1 1         1     1
4         1 1          1     1
5             1 1         1
6               1 1          1


rows = []
cols = []

for i in 1:6
    re = mod2entry(0, 0, )
    push !(rows, re)
end

for i in 1:13

end
H = mod2sparse(6, 13, rows, cols)#mod2sparse version of pcm

################ above is temp pcm stuff ##################

for i in N:
    ch[i] = SBitStream(0.05)
end
max_iter = 100
synd = "0000" #inputvector as string
log_prob_ratios = [] #should this be an SBitStream?
bp_decoding = []
bp_decoding_synd = []
M = size(pcm)
N = size(pcm, 2)
converge = 0
sampleDec = decoder(ch, H, max_iter, synd, log_prob_ratios, bp_decoding, bp_decoding_synd, N, M, converge)

f_verilog, f_circuit = generatehw(bp_decode_log_prob_ratios, dec)
io = open("hwfile.vl", "w")
write(io, f_verilog)
close(io)

