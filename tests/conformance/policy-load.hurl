# AETH-C-008: Policy loading and retrieval
# Load a valid policy
POST http://localhost:8080/api/v1/policies
Content-Type: application/json
{
  "policies": [
    {
      "name": "test-policy",
      "priority": 100,
      "triggers": {},
      "traffic_class_match": {"label_id": "critical"},
      "rules": [
        {"action": "prefer", "link_ids": ["leo_01"]}
      ],
      "conflict_resolution": "lexicographic_policy_name"
    }
  ],
  "defaults": {
    "no_match_action": "defer_to_routing"
  }
}
HTTP 200

# Retrieve the loaded policy
GET http://localhost:8080/api/v1/policies
HTTP 200
[Asserts]
jsonpath "$.policies" count >= 1
