This branch is compiling locally the bp_osd and the ldpc repos
into the `dev` directory where we are hoping to get the bitsad code developed


### Install and start virtual environment
```
python3 -m venv .venv
source .venv/bin/activate
```

### Install requirements
```
pip install -r requirements.txt
```

### Create the dev
```
mkdir -p dev
```

### Compile inplace the ldpc library
```
python setup.py build --build-lib=dev/
```

### Compile inplace the bp_osd library
```
cd src/bp_osd
python3 setup.py build --build-lib=../../dev/
```

### Run the examples/classical_bp_osd_decode_sim.py


