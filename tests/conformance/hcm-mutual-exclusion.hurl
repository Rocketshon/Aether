# AETH-F-008: No concurrent HCM activations

# Activate HCM
POST http://localhost:8080/api/v1/hcm/activate
Content-Type: application/json
{
  "event_type": "emergency",
  "event_id": "mutex-001",
  "actor_id": "operator-1",
  "actor_type": "human_operator",
  "timestamp": "2026-01-01T00:00:00Z",
  "reason": "First activation",
  "scope": ["critical"],
  "authorization_method": "manual",
  "max_duration_seconds": 3600,
  "max_total_duration_seconds": 7200,
  "allow_renewal": false
}
HTTP 200

# Attempt second concurrent activation — must fail
POST http://localhost:8080/api/v1/hcm/activate
Content-Type: application/json
{
  "event_type": "emergency",
  "event_id": "mutex-002",
  "actor_id": "operator-2",
  "actor_type": "human_operator",
  "timestamp": "2026-01-01T00:01:00Z",
  "reason": "Second activation attempt",
  "scope": ["default"],
  "authorization_method": "manual",
  "max_duration_seconds": 3600,
  "max_total_duration_seconds": 7200,
  "allow_renewal": false
}
HTTP 400

# Clean up
POST http://localhost:8080/api/v1/hcm/deactivate
HTTP 200
