// Aether API Authorization Policy
// Loaded via: aether serve --authz-policy deploy/authz-policy.cedar

// Administrators can perform all operations
permit(
    principal == User::"admin",
    action,
    resource
);

// All authenticated users can evaluate traffic, query health, and read policies
permit(
    principal,
    action in [Action::"Evaluate", Action::"IngestTelemetry", Action::"GetPolicy", Action::"QueryAudit", Action::"GetHcmState", Action::"Health"],
    resource
);

// Only operators can modify policies and manage HCM
forbid(
    principal == User::"readonly",
    action in [Action::"LoadPolicy", Action::"ActivateHcm", Action::"DeactivateHcm"],
    resource
);
