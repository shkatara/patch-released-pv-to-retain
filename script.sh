#!/bin/bash

echo Enter the namespace to work with:
read namespace_name

kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="'$namespace_name'")].metadata.name}' |  tr " " "\n" > /tmp/all-pv-in-$namespace_name.txt
for i in $(cat /tmp/all-pv-in-$namespace_name.txt); do kubectl  get pv $i -o custom-columns=Name:.metadata.name,State:.status.phase --no-headers  | grep Released | cut -d' ' -f1 ; done > /tmp/released-pv-in-$namespace_name.txt
size=$(ls -lah /tmp/released-pv-in-$namespace_name.txt |cut -d ' ' -f 5)

if [ $size -gt 0 ]
then  
   echo "patching now"
   for i in $(cat /tmp/released-pv-in-$namespace_name.txt); do kubectl patch pv $i -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'  ; sleep 3 ; done
else
   echo "Will not patch now"
fi
rm -rf /tmp/all-pv-in-$namespace_name.txt /tmp/released-pv-in-$namespace_name.txt
