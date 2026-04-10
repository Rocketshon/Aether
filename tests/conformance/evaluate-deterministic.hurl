# AETH-C-003: Deterministic decisions
# Same input must produce same output

# First evaluation
POST http://localhost:8080/api/v1/evaluate
Content-Type: application/json
{"traffic_class": {"label_id": "critical", "label_source": "DSCP"}}
HTTP 200
[Captures]
first_justification: jsonpath "$.decision.justification"

# Second identical evaluation
POST http://localhost:8080/api/v1/evaluate
Content-Type: application/json
{"traffic_class": {"label_id": "critical", "label_source": "DSCP"}}
HTTP 200
[Asserts]
jsonpath "$.decision.justification" == {{first_justification}}
