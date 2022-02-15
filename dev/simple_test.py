import numpy as np
from bposd.hgp import hgp
from bposd.css_decode_sim import css_decode_sim

from ldpc.codes import rep_code
from ldpc.bp_decode_sim import classical_decode_sim

"""
    FROM BP_OSD
"""
h=np.loadtxt("mkmn_16_4_6.txt").astype(int)
qcode=hgp(h) # construct quantum LDPC code using the symmetric hypergraph product

osd_options={
'error_rate': 0.05,
'target_runs': 1000,
'xyz_error_bias': [0, 0, 1],
'output_file': 'test.json',
'bp_method': "ms",
'ms_scaling_factor': 0,
'osd_method': "osd_cs",
'osd_order': 42,
'channel_update': None,
'seed': 42,
'max_iter': 0,
'output_file': "test.json"
}

lk = css_decode_sim(hx=qcode.hx, hz=qcode.hz, **osd_options)


"""
    FROM LDPC 
"""

d=500

pcm=rep_code(d)
error_rate=0.3

output_dict={}
output_dict['code_type']=f"rep_code_{d}"

output_dict=classical_decode_sim(
    pcm,
    error_rate,
    target_runs=1000,
    max_iter=30,
    seed=100,
    bp_method='ms',
    ms_scaling_factor=1,
    output_file="classical_bp_decode_sim_output.json",
    output_dict=output_dict
)

print(output_dict)



