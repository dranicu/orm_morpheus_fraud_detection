#!/bin/bash

# AI_financial_test
echo "running cloudinit.sh script"

# Install essential packages
apt-get update -y
apt-get install -y dnf-utils zip unzip gcc curl openssl libssl-dev libbz2-dev libffi-dev zlib1g-dev wget make git

echo "INSTALL NVIDIA CUDA + TOOLKIT + drivers"
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
dpkg -i cuda-keyring_1.1-1_all.deb
apt-get update -y
apt-get -y install cuda-toolkit-12-5
apt-get install -y nvidia-driver-555
apt-get -y install cudnn
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit

# Add Docker repository and install Docker
apt-get remove -y runc
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

echo "ENABLE DOCKER"
systemctl enable docker.service

echo "START DOCKER"
systemctl start docker.service

# Python packages
apt-get install -y python3-pip
python3 -m pip install --upgrade pip wheel oci
python3 -m pip install --upgrade setuptools
python3 -m pip install oci-cli langchain python-multipart pypdf six

echo "GROWFS"
growpart /dev/sda 1
resize2fs /dev/sda1

echo "Export nvcc"
echo "export PATH=\$PATH:/usr/local/cuda/bin" >> /home/ubuntu/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64" >> /home/ubuntu/.bashrc

echo "Add docker ubuntu"
usermod -aG docker ubuntu

# Install Python 3.10.6
echo "Python 3.10.6"
wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tar.xz
tar -xf Python-3.10.6.tar.xz
cd Python-3.10.6/
./configure --enable-optimizations
make -j $(nproc)
make altinstall
python3.10 -V
cd ..
rm -rf Python-3.10.6*

# Install Conda
echo "Conda"
mkdir -p /home/ubuntu/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/ubuntu/miniconda3/miniconda.sh
bash /home/ubuntu/miniconda3/miniconda.sh -b -u -p /home/ubuntu/miniconda3
rm -rf /home/ubuntu/miniconda3/miniconda.sh
/home/ubuntu/miniconda3/bin/conda init bash
chown -R ubuntu:ubuntu /home/ubuntu/miniconda3
chown ubuntu:ubuntu /home/ubuntu/.bashrc
su - ubuntu -c "/home/ubuntu/miniconda3/bin/conda init bash"

echo "Creating Conda environment"

# Create the YAML file for Conda environment
su - ubuntu -c "cat << 'EOF' > /home/ubuntu/fraud_conda_env.yaml
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

echo "Check NVIDIA setup"
su - ubuntu -c "sudo nvidia-smi"

echo "Create the environment using Conda"
sudo -u ubuntu -i bash -c "/home/ubuntu/miniconda3/bin/conda env create -f /home/ubuntu/fraud_conda_env.yaml"
echo "/home/ubuntu/miniconda3/bin/conda activate fraud_conda_env" >> /home/ubuntu/.bashrc

echo "Starting Jupyter Notebook server in fraud_conda_env environment"
sudo -u ubuntu -i bash -c "source /home/ubuntu/miniconda3/bin/activate fraud_conda_env && \
                           nohup jupyter notebook --ip=0.0.0.0 --port=8888 > /home/ubuntu/jupyter.log 2>&1 &"

echo "Install the Jupyter kernel"
sudo -u ubuntu -i bash -c "/home/ubuntu/miniconda3/bin/conda run -n fraud_conda_env python -m ipykernel install --user --name fraud_conda_env --display-name 'Fraud Conda Environment'"

echo "Get the Lab files"
sudo -u ubuntu -i bash -c "git clone https://github.com/nv-morpheus/morpheus-experimental"

sudo -u ubuntu -i bash -c "wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/xpbA0K3GmBZGXQv8rkVZ6Nqz0fYqm77VVWIfb3eu9pkEI8n2iRpMvrDjbFheYCeG/n/ocisateam/b/morpheus/o/tabformertransactions.tgz"
sudo -u ubuntu -i bash -c "tar -xzvf tabformertransactions.tgz  -C /home/ubuntu/morpheus-experimental/ai-credit-fraud-workflow/data/TabFormer/raw"

sudo -u ubuntu -i bash -c "wget https://objectstorage.us-ashburn-1.oraclecloud.com/p/8AcyFpGfb5Qa-Vi9kxZ9QZUICfwoe4QoKg_ul8bjYB3B8zDgYTBLPjO-J6zUfCqE/n/ocisateam/b/morpheus/o/sparkovarchive.zip"
apt install unzip
sudo -u ubuntu -i bash -c "unzip sparkovarchive.zip  -d /home/ubuntu/morpheus-experimental/ai-credit-fraud-workflow/data/Sparkov/raw"

date