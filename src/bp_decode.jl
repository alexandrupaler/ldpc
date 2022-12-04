#todo:
#   modify everything to use Julia sparsearrays

using BitSAD
using

#done
#args are m, u, and v respectively in C version
function mod2sparse_mulvec(H, received_codeword, synd)
    M = mod2sparse_rows(H)
    N = mod2sparse_cols(H)

    for 1:M
        synd[i] = 0
    end

    for j in 1:N
        if received_codeword[j] == 1
            for e in mod2sparse_cols[j]
                synd[e.row] ^= 1
            end
        end
    end
end

function mod2sparse_first_in_row(m, i)
    return m.rows[i].right
end
function mod2sparse_first_in_col(m, j)
    return m.cols[j].down
end
function mod2sparse_last_in_row(m, i)
    return m.rows[i].left
end
function mod2sparse_last_in_col(m, j)
    return m.cols[j].up
end

function mod2sparse_next_in_row(e)
    return (e.col + 1)
end
function mod2sparse_next_in_col(e)
    return (e.row + 1)
end
function mod2sparse_prev_in_row(e)
    return (e.col - 1)
end
function mod2sparse_prev_in_col(e)
    return (e.row - 1)
end

function bp_decode_cy()
    bp_decode_log_prob_ratios()

function bp_decode_log_prob_ratios(dec)
#variables that are typically held in the bp_decoder class:
# ch[] (the channel probs)
# H (??)
# max_iter
# synd[] (??)
# log_prob_ratios[]
# bp_decoding[]
# bp_decoding_synd
# N
# M

# for each of the above: am I reading or read/writing? Where is it initialized,
#   and what to? Determine if it needs to be defined before bp_decode_log_prob_ratios
#   (ie as part of the decoder struct) or if it can be defined in this function.
# update: above does not matter, any values which are written to need to be returned
#   (i.e. pass by reference) and any which are read are defined outside. So all in struct.

    #j is the column (second index)
    for j in 1:dec.N #fix syntax
        e = H[mod2sparse_first_in_col(dec.H, j)][j]
        while !(mod2sparse_at_end(e))
            e.bit_to_check = log((1 - dec.channel_probs[j])/(dec.channel_probs[j]))
            e = H[mod2sparse_next_in_col(e)][e.col]

    dec.converge = 0
    for iteration in 1:(dec.max_iter+1)
        #iter = iteration # probably redundant/unused
        #if bp_method==2 #this is the setting for our trial run
        #product sum check_to_bit messages
        # i is the col
        for i in 1:dec.M
            e = H[i][mod2sparse_first_in_row(dec.H, i)]
            temp = 1.0
            while !(mod2sparse_at_end(e))
                e.check_to_bit = temp
                temp *= tanh(e.bit_to_check/2)
                e = H[e.row][mod2sparse_next_in_row(e)]

            e = H[i][mod2sparse_last_in_row(dec.H, i)]
            temp = 1.0
            while !(mod2sparse_at_end(e))
                e.check_to_bit *= temp
                e.check_to_bit = (((-1)^dec.synd[i]) * log((1 + e.check_to_bit) / (1 - e.check_to_bit)))
                temp *= tanh(e.bit_to_check/2)
                e = H[e.row][mod2sparse_prev_in_row(e)]

        # bit-to-check messages
        for j in 1:dec.N
            e = H[mod2sparse_first_in_col(dec.H, j)][j]
            temp = log((1-dec.channel_probs[j]) / (dec.channel_probs[j]))

            while !(mod2sparse_at_end(e)):
                e.bit_to_check = temp
                temp += e.check_to_bit
                e = dec.H[mod2sparse_next_in_col(e)]

            dec.log_prob_ratios[j] = temp
            if temp <= 0
                dec.bp_decoding[j]=1
            else
                dec.bp_decoding[j]=0

            e = mod2sparse_last_in_col(dec.H, j)
            temp = 0.0
            while !(mod2sparse_at_end)
                e.bit_to_check += temp
                temp += e.check_to_bit
                e = mod2sparse_prev_in_col(e)

        #all of these params need to be defined still, as do N and M for the message loops.
        mod2sparse_mulvec(dec.H, dec.bp_decoding, dec.bp_decoding_synd)

        equal = 1
        for check in 1:dec.M
            if dec.synd[check] != dec.bp_decoding_synd[check]
                equal = 0
                break
        if equal == 1
            dec.converge = 1 #how will I use the return value from this?
            return 1

        return 0


function mod2sparse_at_end(e)
    return (e.row < 0)

# I expect that storing mod2entry objects in other mod2entry objects is a very bad
#   idea that will end poorly and not work at all. In that case, my alternative is to
#   store a pointer to the parent mod2sparse object and make left, right, etc. return
#   the correct objects by returning the object at the proper index of owner. This
#   would require dereferencing which is hard.
mutable struct mod2entry()
    bit_to_check #what is this
    check_to_bit #what is this
    row
    col
    sgn #what is this

    left # = owner[col-1]
    right # = owner[col+1]
    up # = owner[row-1]
    down # = owner[row+1]

    # owner #pointer to the mod2sparse object which the mod2entry is a part of
end

mutable struct mod2sparse()
    n_rows::int
    n_cols::int
    rows #array of mod2entry's
    cols #array of mod2entry's
end

mutable struct decoder()
    channel_probs
    H
    max_iter
    synd
    log_prob_ratios #these are defined in bp_decode_log_prob_ratios
    bp_decoding
    bp_decoding_synd
    N
    M
    converge
    bits_to_checks
    checks_to_bits
end

# complicated stuff:
# 2-step process:
#   1. Run the modified decoder with sample parameters. Don't care about result,
#       but as it runs it will populate a julia file with equivalent julia code
#       (including calls to mod2sparse stuff and bp_decode_log_prob_ratios)
#   2. Call generatehw on the populated julia file, write the results to a verilog
#       file.

# There will be a decorator which only works on functions which are prepared for
#   conversion to julia. This decorator will initialize a list L, run the function,
#   then add the hardware generation lines to the end of L, then write L to a jl
#   file. So the above process is accomplished via a decorator.


