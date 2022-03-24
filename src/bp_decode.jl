using BitSAD

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
    return e.right
end
function mod2sparse_next_in_col(e)
    return e.down
end
function mod2sparse_prev_in_row(e)
    return e.left
end
function mod2sparse_prev_in_col(e)
    return e.up
end

#todo:
function bp_decode_cy()
    bp_decode_log_prob_ratios()

function bp_decode_log_prob_ratios()
    for j in 1:n

function mod2sparse_at_end(e)
    return (e.row < 0)

#done
mutable struct mod2entry()
    bit_to_check
    check_to_bit
    row
    col
    sgn

    left
    right
    up
    down
end

mutable struct mod2sparse()
    n_rows::int
    n_cols::int
    rows
    cols
end