#!/bin/bash
# armar_topologia.sh - Arma la topologia de la practica con network namespaces
#
#   Red A 192.168.1.0/24                       Red B 192.168.2.0/24
#   pc1 (.10) --+                                  +-- pc3 (.10)
#               +-- sw1 (br0) -- r1 -- sw2 (br0) --+
#   pc2 (.11) --+   r1-eth0 .1     r1-eth1 .1      +-- pc4 (.11)
#
# Sin rutas por defecto y con ip_forward=0 en r1 (se agregan en el experimento 2).
# Si la topologia ya existe, falla con "File exists": ejecutar limpiar.sh antes.
set -e

# 1) Namespaces
for ns in pc1 pc2 pc3 pc4 r1 sw1 sw2; do
  ip netns add "$ns"
  ip netns exec "$ns" ip link set lo up
done

# 2) Switches: un bridge por namespace de switch
for sw in sw1 sw2; do
  ip netns exec "$sw" ip link add br0 type bridge
  ip netns exec "$sw" ip link set br0 up
done

# 3) Cables (pares veth): conectar <host> <interfaz> <switch> <puerto>
conectar() {
  local host=$1 ifz=$2 sw=$3 puerto=$4
  ip link add "$ifz" type veth peer name "$puerto"
  ip link set "$ifz" netns "$host"
  ip link set "$puerto" netns "$sw"
  ip netns exec "$sw" ip link set "$puerto" master br0
  ip netns exec "$sw" ip link set "$puerto" up
  ip netns exec "$host" ip link set "$ifz" up
}

conectar pc1 pc1-eth0 sw1 sw1-p1
conectar pc2 pc2-eth0 sw1 sw1-p2
conectar r1  r1-eth0  sw1 sw1-p3
conectar pc3 pc3-eth0 sw2 sw2-p1
conectar pc4 pc4-eth0 sw2 sw2-p2
conectar r1  r1-eth1  sw2 sw2-p3

# 4) Direcciones IP
ip netns exec pc1 ip addr add 192.168.1.10/24 dev pc1-eth0
ip netns exec pc2 ip addr add 192.168.1.11/24 dev pc2-eth0
ip netns exec r1  ip addr add 192.168.1.1/24  dev r1-eth0
ip netns exec r1  ip addr add 192.168.2.1/24  dev r1-eth1
ip netns exec pc3 ip addr add 192.168.2.10/24 dev pc3-eth0
ip netns exec pc4 ip addr add 192.168.2.11/24 dev pc4-eth0

# 5) Reenvio desactivado en el router (se activa en el experimento 2)
ip netns exec r1 sysctl -q -w net.ipv4.ip_forward=0

echo "Topologia armada. Namespaces:"
ip netns list
