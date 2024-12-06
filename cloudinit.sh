#!/bin/bash

#AI_financial_test
echo "running cloudinit.sh script"

dnf install -y dnf-utils zip unzip gcc
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf remove -y runc

echo "INSTALL DOCKER"
dnf install -y docker-ce --nobest

echo "ENABLE DOCKER"
systemctl enable docker.service

echo "INSTALL NVIDIA CONT TOOLKIT"
dnf install -y nvidia-container-toolkit

echo "START DOCKER"
systemctl start docker.service

echo "PYTHON packages"
python3 -m pip install --upgrade pip wheel oci
python3 -m pip install --upgrade setuptools
python3 -m pip install oci-cli
python3 -m pip install langchain
python3 -m pip install python-multipart
python3 -m pip install pypdf
python3 -m pip install six

echo "GROWFS"
/usr/libexec/oci-growfs -y


echo "Export nvcc"
sudo -u opc bash -c 'echo "export PATH=\$PATH:/usr/local/cuda/bin" >> /home/opc/.bashrc'
sudo -u opc bash -c 'echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64" >> /home/opc/.bashrc'

echo "Add docker opc"
usermod -aG docker opc

echo "CUDA toolkit"
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
dnf clean all
dnf -y install cuda-toolkit-12-4
dnf -y install cudnn

echo "Python 3.10.6"
dnf install curl gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make -y
wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tar.xz
tar -xf Python-3.10.6.tar.xz
cd Python-3.10.6/
./configure --enable-optimizations
make -j $(nproc)
sudo make altinstall
python3.10 -V
cd ..
rm -rf Python-3.10.6*

echo "Git"
dnf install -y git

echo "Conda"
mkdir -p /home/opc/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/opc/miniconda3/miniconda.sh
bash /home/opc/miniconda3/miniconda.sh -b -u -p /home/opc/miniconda3
rm -rf /home/opc/miniconda3/miniconda.sh
/home/opc/miniconda3/bin/conda init bash
chown -R opc:opc /home/opc/miniconda3
su - opc -c "/home/opc/miniconda3/bin/conda init bash"

# Ensure the .bashrc is reloaded
sudo -u opc bash -c "source /home/opc/.bashrc"

echo "Creating Conda environment"

# Create the YAML file and redirect it to fraud_conda_env.yaml
su - opc -c "cat << 'EOF' > /home/opc/fraud_conda_env.yaml
name: fraud_conda_env
channels:
  - rapidsai
  - rapidsai-nightly
  - pyg
  - conda-forge
  - nvidia
dependencies:
  - breathe
  - conda-forge::category_encoders
  - cmake>=3.26.4,!=3.30.0
  - cuda-cudart-dev
  - cuda-nvtx-dev
  - cuda-profiler-api
  - cuda-version=12.1
  - cudf==24.8.*
  - cugraph==24.8.*
  - cugraph-pyg==24.8.*
  - cuml==24.8.*
  - cupy>=12.0.0
  - cython>=3.0.0
  - doxygen
  - graphviz
  - ipython
  - jupyter
  - libcublas-dev
  - libcurand-dev
  - libcusolver-dev
  - libcusparse-dev
  - nbsphinx
  - ninja
  - notebook>=0.5.0
  - numba>=0.57
  - numpy>=1.23,<2.0a0
  - conda-forge::matplotlib
  - pandas
  - pre-commit
  - pydantic
  - pydata-sphinx-theme
  - pyg::pyg
  - pylibcugraphops==24.8.*
  - pylibraft==24.8.*
  - pylibwholegraph==24.8.*
  - pytest
  - pytorch-cuda=12.1
  - pytorch::pytorch>=2.0,<2.2.0a0
  - py-xgboost-gpu
  - rmm==24.8.*
  - scikit-build-core>=0.7.0
  - scipy
  - setuptools>=61.0.0
  - sphinx-copybutton
  - sphinx-markdown-tables
  - sphinx<6
  - sphinxcontrib-websupport
  - torchdata
  - tensordict
  - wget
  - wheel
EOF"


# Create the Conda env_domino environment
su - opc -c "/home/opc/miniconda3/bin/conda env create -f /home/opc/fraud_conda_env.yaml"

echo "source activate fraud_conda_env" >> /home/opc/.bashrc
echo "Starting Jupyter Notebook server as opc and fraud_conda_env env"

# Start Jupyter Notebook server
su - opc -c "source /home/opc/.bashrc && \
             conda activate fraud_conda_env && \
             nohup jupyter notebook --ip=0.0.0.0 --port=8888 > /home/opc/jupyter.log 2>&1 &"


echo "Creating kernel execution for Jupyter fraud_conda_env"


# Install the Jupyter kernel
su - opc -c "/home/opc/miniconda3/bin/conda run -n fraud_conda_env python -m ipykernel install --user --name fraud_conda_env --display-name 'Fraud Conda Environment'"

# Get the LAB files:
su - opc -c "git clone https://github.com/nv-morpheus/morpheus-experimental"

echo "Get the Lab files"
su - opc -c  "git clone https://github.com/nv-morpheus/morpheus-experimental"

su - opc -c  "wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/xpbA0K3GmBZGXQv8rkVZ6Nqz0fYqm77VVWIfb3eu9pkEI8n2iRpMvrDjbFheYCeG/n/ocisateam/b/morpheus/o/tabformertransactions.tgz"
su - opc -c  "tar -xzvf tabformertransactions.tgz  -C /home/opc/morpheus-experimental/ai-credit-fraud-workflow/data/TabFormer/raw/"

su - opc -c  "wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/8AcyFpGfb5Qa-Vi9kxZ9QZUICfwoe4QoKg_ul8bjYB3B8zDgYTBLPjO-J6zUfCqE/n/ocisateam/b/morpheus/o/sparkovarchive.zip"
yum install unzip
su - opc -c
su - opc -c "unzip sparkovarchive.zip  -d /home/opc/morpheus-experimental/ai-credit-fraud-workflow/data/Sparkov/raw"


date