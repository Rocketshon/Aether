# Aether Multi-Link Test Topology

A Containerlab topology for integration testing Aether's multi-provider arbitration.

## Prerequisites

- [Containerlab](https://containerlab.dev/) installed
- Docker with the `aether-ref:latest` image built (`cd ../aether-ref/deploy && docker compose build`)

## Topology

```
satellite-gw (40ms delay, 2% loss) <---> aether-controller <---> terrestrial-gw (no impairment)
                                              |
cellular-gw (15ms delay) <------------------->

client connected to all three gateways
```

## Usage

```bash
# Deploy
sudo containerlab deploy -t aether-multilink.clab.yml

# Verify
docker exec clab-aether-multilink-client curl -sf http://clab-aether-multilink-aether-controller:8080/api/v1/health

# Test failover: kill satellite link
docker exec clab-aether-multilink-satellite-gw tc qdisc change dev eth1 root netem loss 100%

# Destroy
sudo containerlab destroy -t aether-multilink.clab.yml
```
