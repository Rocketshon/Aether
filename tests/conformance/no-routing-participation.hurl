# AETH-C-010: No routing protocol participation
# Aether must not expose routing protocol endpoints

GET http://localhost:8080/api/v1/bgp
HTTP 404

GET http://localhost:8080/api/v1/ospf
HTTP 404

GET http://localhost:8080/api/v1/isis
HTTP 404

# Only documented endpoints should exist
GET http://localhost:8080/api/v1/nonexistent
HTTP 404
