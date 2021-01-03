#!/bin/bash
az vmss list-instance-public-ips -g MC_ri-eastus-rg_ca_eastus -n aks-publicpool-60863648-vmss -o table