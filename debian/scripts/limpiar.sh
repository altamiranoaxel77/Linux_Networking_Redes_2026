#!/bin/bash
# limpiar.sh - Borra la topologia de la practica.
# Al borrar un namespace se eliminan tambien sus interfaces veth y bridges.
for ns in pc1 pc2 pc3 pc4 r1 sw1 sw2; do
  ip netns del "$ns" 2>/dev/null
done
echo "Topologia eliminada. Namespaces restantes:"
ip netns list
