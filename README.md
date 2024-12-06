# **ORM_stack_a10_gpu_ai_fin**

# **ORM Stack to deploy an A10 shape, one GPU different scenarios for testing financial services**

- [Intallation](#installation)
- [Note](#note)
- [Systems monitoring](#systems-monitoring)
- [Jupyter access](#jupyter-access)
- [Fraud Detection Models](#fraud-detection-models)

## Installation
- **you can use Resource Manager from OCI console to upload the code from here**
- **once the instance is created, wait the cloud init completion and then you can allow firewall access to be able launch the jupyter notebook interface, commands detailed on both Oracle Linux and Ubuntu in the [Jupyter_access](#jupyter_access)**

- **Jupyter notebook has already configured triton_example_kernel and domino_example_kernel environments**
- **to switch between them you can open each notebook then go to Kernel -> Change kernel -> Select [domino_example_kernel or triton_example_kernel]**

## NOTE
- **the code deploys an A10 shape with one GPU Shape**
- **based on your need you have the option to either create a new VCN and subnet or you ca use an existing VCN and a subnet where the VM will be deployed**
- **it will add a freeform TAG : "GPU_TAG"= "A10-1"**
- **the boot vol is 500 GB**
- **the cloudinit will do all the steps needed to download and install all Jupyter notebooks and needed Python packages**

## Systems monitoring
- **Some commands to check the progress of cloudinit completion and GPU resource utilization:**
```
monitor cloud init completion: tail -f /var/log/cloud-init-output.log
monitor single GPU: nvidia-smi dmon -s mu -c 100
                    watch -n 2 'nvidia-smi'
monitor the system in general: sar 3 1000
```
## Jupyter access
### Enable access to Jupyter on both Oracle Linux and Ubuntu:

- **Oracle Linux:**
```
sudo firewall-cmd --zone=public --permanent --add-port 8888/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all

!!! in case that you reboot the system you will need to manually start jupyter notebook:
make sure you execute the following commands from /home/opc
conda activate triton_example
> jupyter.log
nohup jupyter notebook --ip=0.0.0.0 --port=8888 > /home/opc/jupyter.log 2>&1 &
then cat jupyter.log to collect the token for the access
```
- **Ubuntu:**
```
sudo iptables -L
sudo iptables -F
sudo iptables-save > /dev/null

If this does not work do also this:
sudo systemctl stop iptables
sudo systemctl disable iptables

sudo systemctl stop netfilter-persistent
sudo systemctl disable netfilter-persistent

sudo iptables -F
sudo iptables-save > /dev/null

!!! in case that you reboot the system you will need to manually start jupyter notebook:
make sure you execute the following commands from /home/ubuntu
conda activate triton_example
> jupyter.log
nohup jupyter notebook --ip=0.0.0.0 --port=8888 > /home/ubuntu/jupyter.log 2>&1 &
then cat jupyter.log to collect the token for the access
```
## Fraud Detection Notebooks details
### The instance contains Jupyter notebooks from the following fraud detection models:
Tabformer and Sparkov:
https://github.com/nv-morpheus/morpheus-experimental/tree/branch-24.10/ai-credit-fraud-workflow
## Fraud Detection Models
Notebooks need to be executed in the correct order.
For a particular dataset, the preprocessing notebook must be executed before the training notebook. Once the training notebook produces models, the inference notebook can be executed to run inference on unseen data.

You can go from Jupyter to the following location: /morpheus-experimental/ai-credit-fraud-workflow/notebooks/ and then you can execute the following labs (Please select Kernel -> Change Kernel -> Fraud Conda Environment for all those):

### TabFormer steps and notebooks:
To execute the labs select Kernel -> Restart Kernel and Run All Cells
1. preprocess_Tabformer.ipynb -> This will produce a number of files under ./data/TabFormer/gnn and ./data/TabFormer/xgb. It will also save data preprocessor pipeline preprocessor.pkl and a few variables in a json file variables.json under ./data/TabFormer directory.

2. train_gnn_based_xgboost.ipynb -> This will produce two files for the GNN-based XGBoost model under ./data/TabFormer/models directory. Note: Please be aware to set cell 2 with this value: DATASET = TABFORMER

3. inference_gnn_based_xgboost_TabFormer.ipynb -> This is used for Inference. Note: Please be aware to set cell 2 with this value: dataset_base_path = '../data/TabFormer/' and keep the same TabFormer sekection uncommented in cell 13.

Optional: Pure XGBoost
Two additional notebooks are provided to build a pure XGBoost model (without GNN) and perform inference using that model.
1. train_xgboost.ipynb -> This will produce a XGBoost model under ./data/TabFormer/models directory. Note: Please be aware to set cell 2 with this value: DATASET = TABFORMER
2. inference_xgboost_TabFormer.ipynb -> This is used for inference

### Spakov steps and notebooks:
To execute the labs select Kernel -> Restart Kernel and Run All Cells

1. preprocess_Sparkov.ipynb -> This will produce a number of files under ./data/Sparkov/gnn and ./data/Sparkov/xgb. It will also save data preprocessor pipeline preprocessor.pkl and a few variables in a json file variables.json under ./data/Sparkov directory.

2. train_gnn_based_xgboost.ipynb -> This will produce two files for the GNN-based XGBoost model under ./data/Sparkov/models directory. Note: Please be aware to set cell 2 with this value: DATASET = SPARKOV

Optional: Pure XGBoost
Two additional notebooks are provided to build a pure XGBoost model (without GNN) and perform inference using that model.
1. train_xgboost.ipynb -> This will produce a XGBoost model under ./data/Sparkov/models directory. Note: Please be aware to set cell 2 with this value: DATASET = SPARKOV
2. inference_xgboost_Sparkov.ipynb -> This is used for inference. Note: Please be aware to set cell 2 with this value: dataset_base_path = '../data/Sparkov/' and keep the same Sparkov content selection uncommented in cell 13.
