# Install and start virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Compile inplace the library
python setup.py build --build-lib=.

# Run the examples/classical_bp_osd_decode_sim.py


