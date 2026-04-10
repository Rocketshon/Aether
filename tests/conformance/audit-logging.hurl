# AETH-C-007: Audit logging completeness
# Every decision must be recorded in the audit log

# Trigger a decision
POST http://localhost:8080/api/v1/evaluate
Content-Type: application/json
{"traffic_class": {"label_id": "default", "label_source": "DSCP"}}
HTTP 200
[Captures]
decision_id: jsonpath "$.decision.decision_id"

# Verify it appears in the audit log
GET http://localhost:8080/api/v1/audit
HTTP 200
[Asserts]
jsonpath "$.entries" count >= 1
jsonpath "$.entries[0].hmac" exists
