# CentOS + HPC + NVIDIA + Docker

This is a Packer configuration that can be sued to generate a managed image:

- CentOS HPC (currently 7.4)
- CUDA drivers
- NVIDIA GRID drivers

To use the Packer configuration, set the environment variables containing Service Principal credentials:

```
export ARM_CLIENT_ID=
export ARM_CLIENT_SECRET=
export ARM_TENANT_ID=
export ARM_SUBSCRIPTION_ID=
```

Create a Resource Group where the Managed Image will be created, e.g.:

```
az group create -n centos-hpc-nvidia -l westeurope
```

Then run:

```
packer build centos-hpc-nvidia.json
```

Give the image a quick test:

```
az vm create -n nvidia-smoke-test -g centos-hpc-nvidia --image centos-hpc-nvidia --size Standard_NV6_Promo --ssh-key-value ~/.ssh/id_rsa.pub
```
