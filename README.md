# Packer configuration for NVIDIA + Docker custom images on Azure

This is a Packer configuration that can be used to generate custom managed Azure VM images:

- CentOS-HPC (7.4) or standard Ubuntu (18.04)
- NVIDIA GRID drivers on NV* hosts
- CUDA Toolkit
- Docker CE

These images are designed to be used in Azure Batch container-enabled pools, in order to run container-based batch jobs that require access to a GPU: either via CUDA or the NVIDIA GRID driver on suitable machine types (e.g. NV*).

To use the Packer configuration, set the environment variables containing Service Principal credentials with subscription-level :

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

or:

```
az group create -n ubuntu-nvidia -l westeurope
```

Then run:

```
packer build centos-hpc-nvidia.json
```

or:

```
packer build ubuntu-nvidia.json
```

Give the image a quick test:

```
az vm create -n nvidia-smoke-test -g centos-hpc-nvidia --image centos-hpc-nvidia --size Standard_NV6_Promo --ssh-key-value ~/.ssh/id_rsa.pub
```

or:

```
az vm create -n ubuntu-smoke-test -g ubuntu-nvidia --image ubuntu-nvidia --size Standard_NV6_Promo --ssh-key-value ~/.ssh/id_rsa.pub
```

## Using the images with Azure Batch

Nota bene: in order to use a custom image in a Batch pool, it is recommended to use the Shared Image Gallery service. The article below, from the Batch Shipyard project documentation, gives some indications on how to do this.

[Creating Images for use with Azure Batch and Batch Shipyard](https://batch-shipyard.readthedocs.io/en/latest/63-batch-shipyard-custom-images/#creating-images-for-use-with-azure-batch-and-batch-shipyard)
