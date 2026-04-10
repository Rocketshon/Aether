# AETH-C-007: Health endpoint
GET http://localhost:8080/api/v1/health
HTTP 200
[Asserts]
jsonpath "$.status" exists
