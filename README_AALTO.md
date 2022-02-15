# Install and start virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Compile inplace the ldpc library
python setup.py build --build-lib=.

# Compile inplace the bp_osd library
cd src/bp_osd
python3 setup.py build --build-lib=../../

# Run the examples/classical_bp_osd_decode_sim.py


