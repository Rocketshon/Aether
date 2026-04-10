# HCM Level 2: Lifecycle management

# Verify HCM is initially inactive
GET http://localhost:8080/api/v1/hcm/state
HTTP 200
[Asserts]
jsonpath "$.active" == false

# Activate HCM
POST http://localhost:8080/api/v1/hcm/activate
Content-Type: application/json
{
  "event_type": "emergency",
  "event_id": "test-001",
  "actor_id": "operator-1",
  "actor_type": "human_operator",
  "timestamp": "2026-01-01T00:00:00Z",
  "reason": "Conformance test",
  "scope": ["critical"],
  "authorization_method": "manual",
  "max_duration_seconds": 3600,
  "max_total_duration_seconds": 7200,
  "allow_renewal": false
}
HTTP 200

# Verify HCM is active
GET http://localhost:8080/api/v1/hcm/state
HTTP 200
[Asserts]
jsonpath "$.active" == true

# Deactivate HCM
POST http://localhost:8080/api/v1/hcm/deactivate
HTTP 200

# Verify HCM is inactive again
GET http://localhost:8080/api/v1/hcm/state
HTTP 200
[Asserts]
jsonpath "$.active" == false
