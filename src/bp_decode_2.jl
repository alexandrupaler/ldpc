#This is a new version of the necessary mod2sparse functions for decoding which makes use
# of the sparsearrays library in julia.

#Need to get first and last non-zero element in each row/col of a sparse matrix

#SBitStream values: channel probabilities, check_to_bit values, bit_to_check values,

#Need to store bit_to_check and check_to_bit for each entry in the sparse matrix
# Possible options:
#   1. Two parallel sparse matrices, one for bit_to_check and one for check_to_bit.
#   2. Two arrays parallel with m.nzval of bit_to_check messages and check_to_bit messages.

using BitSAD

#DONE:

#these are redundant. Access bit_to_check for an entry at the index of that entry in nzval.
#and same for check_to_bit, as these are 3 parallel arrays.
function mod2sparse_bit_to_check(bits_to_checks, i)
    return bits_to_checks[i]
end

function mod2sparse_check_to_bit(checks_to_bits, i)
    return checks_to_bits[i]
end

#TODO:



#MOSTLY DONE:

#Note: m.colptr is always of size n+1 for a matrix of n non-zero elements.
#Q: How should this function behave in the absence of a non-zero element in the column?
#A: For now, assume this is never the case. TODO: ACTUALLY ANSWER THIS LATER
#returns the index of the value in nzval associated with the first non-zero element of row i in sparse matrix m.
function mod2sparse_first_in_col(m, i)
    return m.colptr[i]
end

function mod2sparse_last_in_col(m, i) #No index out of bounds error because colptr is 1 too large.
    return (m.colptr[i+1] - 1)
end

#returns true if e is the last nz element in the column of m, false otherwise.
#TODO: make this such that m does not need to be passed as a parameter.
function mod2sparse_at_end(m, j, e)
    return (m.colptr[j+1] == e)
end

#returns the nzval index associated with the next nz value in a matrix.
#TODO: get rid of this function call, only kept for now to mirror original structure.
function mod2sparse_next_in_col(e)
    return e+1
end

#IN PROGRESS:

#SHOULD TRY TO ACCESS BY COLUMN, NOT ROW.
function mod2sparse_first_in_row(m, i) #m is assumed to be a SparseMatrixCSC struct
    return m.nzval[]
end

function mod2sparse_last_in_row()
    return m.rowval[]
end

function bp_decode_log_prob_ratios(dec)
    for j in 1:dec.N
        # e is first non-zero entry in column j of H.
        e = mod2sparse_first_in_col(dec.H, j)
        while !(mod2sparse_at_end(m, j, e))
            dec.bits_to_checks[e] = log((1 - dec.channel_probs[j]) / (dec.channel_probs[j]))
            e = mod2sparse_next_in_col(e)

    dec.converge = 0
    #TODO: change this to go by columns rather than by rows, Julia is column-major.
    for iteration in 1:(dec.max_iter+1)
        for i in 1:dec.M
            e = mod2sparse_first_in_row(dec.H, i)
end