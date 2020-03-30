# Delete cluster to remove an imported cluster does not work

## Symptom

If cluster deletion is unsuccessful, you can force removal of the `multicluster-endpoint` from the managed cluster.

## Resolving the problem

  1. Open your terminal and configure your `kubectl` for your managed cluster.

See [Supported cloud providers](https://www.ibm.com/support/knowledgecenter/SSFC4F_1.2.0/mcm/manage_cluster/cloud_providers.html?view=kc) to learn how to configure your `kubectl`.

  2. Run the following `self-destruct` command to remove the multicluster-endpoint from your managed cluster:
    
    docker run -it --entrypoint=cp -v /tmp:/data ibmcom/icp-multicluster-endpoint-operator:3.2.1 /usr/local/bin/self-destruct.sh /data/self-destruct.sh; /tmp/self-destruct.sh 2>&1 | tee self-destruct.log; rm /tmp/self-destruct.sh [![Copy](https://www.ibm.com/support/knowledgecenter/images/icons/copy.png)](javascript:void(0);)

The force deletion might take a few minutes.

[Source](https://www.ibm.com/support/knowledgecenter/en/SSFC4F_1.2.0/mcm/troubleshoot/delete_import.html)
