use cedar_policy::{
    Authorizer, Context, Decision, Entities, EntityUid, PolicySet, Request, Schema,
};
use std::path::Path;

use crate::error::{AetherError, Result};

/// Cedar-based authorization for the Aether HTTP API.
///
/// Maps HTTP requests to Cedar authorization decisions:
/// - Principal: extracted from X-Aether-Principal header
/// - Action: derived from HTTP method + path (e.g., LoadPolicy, Evaluate)
/// - Resource: the API resource being accessed (e.g., policy, hcm, audit)
pub struct CedarAuthorizer {
    policy_set: PolicySet,
    authorizer: Authorizer,
}

impl CedarAuthorizer {
    /// Load Cedar policies from a string.
    pub fn from_policy_str(policy_src: &str) -> Result<Self> {
        let policy_set = policy_src
            .parse::<PolicySet>()
            .map_err(|e| AetherError::Authorization(format!("Cedar policy parse error: {e}")))?;

        Ok(Self {
            policy_set,
            authorizer: Authorizer::new(),
        })
    }

    /// Load Cedar policies from a .cedar file.
    pub fn from_file(path: &Path) -> Result<Self> {
        let src = std::fs::read_to_string(path)?;
        Self::from_policy_str(&src)
    }

    /// Authorize a request.
    ///
    /// Returns Ok(()) if allowed, Err(Authorization) if denied.
    pub fn authorize(
        &self,
        principal: &str,
        action: &str,
        resource: &str,
    ) -> Result<()> {
        let principal_uid: EntityUid = format!("User::\"{principal}\"")
            .parse()
            .map_err(|e| AetherError::Authorization(format!("invalid principal: {e}")))?;

        let action_uid: EntityUid = format!("Action::\"{action}\"")
            .parse()
            .map_err(|e| AetherError::Authorization(format!("invalid action: {e}")))?;

        let resource_uid: EntityUid = format!("Resource::\"{resource}\"")
            .parse()
            .map_err(|e| AetherError::Authorization(format!("invalid resource: {e}")))?;

        let request = Request::new(
            principal_uid,
            action_uid,
            resource_uid,
            Context::empty(),
            None::<&Schema>,
        )
        .map_err(|e| AetherError::Authorization(format!("request construction error: {e}")))?;

        let entities = Entities::empty();
        let response = self.authorizer.is_authorized(&request, &self.policy_set, &entities);

        match response.decision() {
            Decision::Allow => Ok(()),
            Decision::Deny => Err(AetherError::Authorization(format!(
                "access denied: {principal} cannot {action} on {resource}"
            ))),
        }
    }
}

/// Map an HTTP method + path to a Cedar action name.
pub fn action_for_route(method: &str, path: &str) -> &'static str {
    match (method, path) {
        ("POST", p) if p.contains("/policies") => "LoadPolicy",
        ("GET", p) if p.contains("/policies") => "GetPolicy",
        ("POST", p) if p.contains("/evaluate") => "Evaluate",
        ("POST", p) if p.contains("/telemetry") => "IngestTelemetry",
        ("GET", p) if p.contains("/audit") => "QueryAudit",
        ("POST", p) if p.contains("/hcm/activate") => "ActivateHcm",
        ("POST", p) if p.contains("/hcm/deactivate") => "DeactivateHcm",
        ("GET", p) if p.contains("/hcm/state") => "GetHcmState",
        ("GET", p) if p.contains("/health") => "Health",
        _ => "Unknown",
    }
}

/// Map an HTTP path to a Cedar resource name.
pub fn resource_for_route(path: &str) -> &'static str {
    if path.contains("/policies") {
        "policy"
    } else if path.contains("/evaluate") {
        "evaluation"
    } else if path.contains("/telemetry") {
        "telemetry"
    } else if path.contains("/audit") {
        "audit"
    } else if path.contains("/hcm") {
        "hcm"
    } else if path.contains("/health") {
        "health"
    } else {
        "unknown"
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const TEST_POLICY: &str = r#"
permit(
    principal == User::"admin",
    action,
    resource
);

permit(
    principal,
    action in [Action::"Evaluate", Action::"Health", Action::"GetPolicy"],
    resource
);

forbid(
    principal == User::"readonly",
    action in [Action::"LoadPolicy", Action::"ActivateHcm"],
    resource
);
"#;

    #[test]
    fn admin_can_do_anything() {
        let authz = CedarAuthorizer::from_policy_str(TEST_POLICY).unwrap();
        assert!(authz.authorize("admin", "LoadPolicy", "policy").is_ok());
        assert!(authz.authorize("admin", "ActivateHcm", "hcm").is_ok());
    }

    #[test]
    fn anyone_can_evaluate() {
        let authz = CedarAuthorizer::from_policy_str(TEST_POLICY).unwrap();
        assert!(authz.authorize("readonly", "Evaluate", "evaluation").is_ok());
        assert!(authz.authorize("unknown-user", "Health", "health").is_ok());
    }

    #[test]
    fn readonly_cannot_load_policy() {
        let authz = CedarAuthorizer::from_policy_str(TEST_POLICY).unwrap();
        assert!(authz.authorize("readonly", "LoadPolicy", "policy").is_err());
    }
}
