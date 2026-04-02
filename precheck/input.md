# OpenShift Cluster Upgrade Pre-Check Analysis

<constraints>
- YOU SHOULD ALWAYS CALL THE TOOLS TO GET THE INFORMATION. YOU SHOULD NEVER TREAT DATA FROM EXAMPLES AS REAL DATA.
- YOU SHOULD ALWAYS REFERENCE REAL DATA FROM TOOL CALLS. IF REAL DATA IS NOT AVAILABLE, NOTIFY THE USER AND REFUSE TO ANSWER USING INCORRECT DATA BUT DO NOT USE PLACEHOLDER OR DUMMY DATA.
- YOU MUST analyze the actual ClusterVersion AND ClusterOperator data provided in the attachments
- NEVER use placeholder or dummy data - only reference real data from the attachments
- ONLY report issues that are actually present in the data
- ONLY OUTPUT the Summary and TL;DR sections
- Be specific about the source of any issues identified
- CRITICAL: When counting available updates, count ALL array elements in status.availableUpdates

<language_validation>
BEFORE providing your response, verify:
1. Every word in your response is in the target language (except system identifiers like file paths, URLs, command names)
2. Technical terms are translated or explained in the target language
3. No English phrases or mixed language content exists in your explanations
4. All section headers and content follow the target language requirements
</language_validation>
</constraints>

<context>
This is a pre-upgrade analysis for OpenShift cluster version 4.21.4. You have complete cluster data including ClusterVersion and all ClusterOperator resources. Focus on identifying real blockers that would prevent or disrupt cluster upgrades.
</context>

<critical_analysis_requirements>

1. **Rich Available Updates Analysis**:
   - Count EXACTLY how many items are in the status.availableUpdates array
   - Extract update metadata for each available update:
     * Version and image information
     * Available channels for each update (from channels array)
     * Errata/release links (from url field) if available
     * Identify the latest recommended update
   - Analyze current channel strategy and available channel options

2. **Cluster Upgrade Readiness Analysis**:
   - Check status.conditions for type="Upgradeable" (OPTIONAL condition)
     * If Upgradeable=False, this IS an upgrade blocker for MINOR upgrades - report the specific reason and message
     * If Upgradeable=True, missing, or Unknown - upgrades are allowed
   - Check status.conditions for type="Failing"
     * If Failing=True, this indicates cluster reconciliation issues - report details
   - Check status.conditions for type="Available"
     * If Available=False, this indicates cluster operational issues
   - Note: Upgradeable condition is optional and may not be present in all clusters

3. **ClusterOperator Health Check** (Using Official OpenShift Standards):
   - **Available=False**: Component requires immediate administrator intervention (upgrade blocker)
   - **Degraded=True**: Component doesn't match desired state, may have lower quality of service
   - **Progressing=True with errors**: Component stuck rolling out changes (potential blocker)
   - **Upgradeable=False**: Component explicitly blocks minor upgrades until resolved
   - Report specific operator names and their condition messages
   - Focus on Available=False and Upgradeable=False as primary upgrade blockers

4. **User Workload PDB Analysis** (IMPORTANT - Filter System PDBs):
   - Query PodDisruptionBudgets in ALL namespaces EXCEPT these OpenShift system namespaces:
     * openshift-* (all openshift- prefixed namespaces)
     * kube-* (all kube- prefixed namespaces)
     * default, openshift
   - ONLY flag user workload PDBs where:
     * minAvailable >= 1 AND it covers critical user applications
     * maxUnavailable = 0 AND it covers critical user applications
   - IGNORE all PDBs in OpenShift system namespaces - these are managed by Red Hat
   - If no problematic user workload PDBs exist, state "No problematic user workload PDBs found"

5. **MachineConfigPool Status**:
   - Check for Degraded=True, spec.paused=true, or observedGeneration ≠ metadata.generation
   - These indicate node configuration issues that block upgrades
   - Focus on master and worker MCPs which are critical for upgrade success

6. **Node and Infrastructure Issues**:
   - Check Node resources for NotReady conditions
   - Identify nodes with scheduling issues or resource constraints
   - Look for infrastructure problems affecting the upgrade

7. **Cluster Capabilities Assessment**:
   - Extract enabled capabilities from status.capabilities.enabledCapabilities
   - Extract known capabilities from status.capabilities.knownCapabilities
   - Identify disabled capabilities (known but not enabled)
   - Assess capability health impact on upgrades
   - Check spec.capabilities.baselineCapabilitySet and additionalEnabledCapabilities

8. **Update Channel Strategy Analysis**:
   - Current channel from spec.channel
   - Available channels for current version from status.desired.channels
   - Channel recommendations based on version and use case
   - EUS (Extended Update Support) upgrade path options if applicable

9. **Cincinnati Update Service Health**:
   - Check spec.upstream (if configured) or note "using default Red Hat update service"
   - Verify status.conditions for type="RetrievedUpdates" status and timestamp
   - Confirm status.availableUpdates is populated (indicates working service)
   - Cluster ID for telemetry (spec.clusterID)
   - Signature verification status (spec.signatureStores if present, otherwise default stores)

10. **Cluster Version History Context**:
   - Extract initial cluster version from status.history (first entry)
   - Identify upgrade path from history entries
   - Last completed upgrade and timeframe
   - Any partial or failed upgrade attempts
   - Total cluster age and upgrade frequency

11. **Configuration Overrides Analysis**:
   - Review spec.overrides for any unmanaged components that might block upgrades
   - Distinguish between supported capabilities exclusion vs unsupported overrides
   - Check for configuration settings that could impact upgrade processes

</critical_analysis_requirements>

<output_format>
## Summary

**Available Updates Analysis**
- **Update Count**: [Total count of ALL items in status.availableUpdates array]
- **Available Versions**: [List of available versions with channels, e.g., "4.21.4 (stable-4.21, fast-4.21)", "4.22.0 (candidate-4.22)"]
- **Latest Update**: [Most recent version with errata link if available, e.g., "4.21.4 - https://access.redhat.com/errata/RHSA-2026:2984"]
- **Channel Recommendations**: [Current channel and suggested options based on release readiness]

**Cluster Capabilities Configuration**
- **Enabled Capabilities**: [List from status.capabilities.enabledCapabilities, e.g., "Console, marketplace, openshift-samples"]
- **Disabled Capabilities**: [Known capabilities not enabled, e.g., "baremetal, insights"]
- **Capability Set**: [From spec.capabilities.baselineCapabilitySet, e.g., "vCurrent"]
- **Capability Health**: [Any capability-related issues affecting upgrades]

**Update Service Health**
- **Cincinnati Service**: [spec.upstream URL if configured, otherwise "Default Red Hat update service"]
- **Service Status**: [RetrievedUpdates condition status and message]
- **Last Update Check**: [From RetrievedUpdates condition lastTransitionTime]
- **Update Channel**: [Current spec.channel, e.g., "stable-4.21"]
- **Cluster ID**: [spec.clusterID for telemetry]

**Cluster History Context**
- **Initial Version**: [First entry from status.history, e.g., "4.20.0 (installed Jan 2026)"]
- **Upgrade Path**: [Recent version progression from history]
- **Last Completed Upgrade**: [Most recent completed entry with timeframe]
- **Cluster Age**: [Time since initial installation]

**Upgrade Readiness Assessment**
- Whether upgrades are currently blocked (check Upgradeable=False if present, Failing=True, or degraded operators)
- Any problematic USER WORKLOAD PDBs (not OpenShift system PDBs)
- Unhealthy operators that would impact upgrades
- MCP issues that would prevent node updates
- Configuration overrides vs supported capability exclusions

If no critical issues are found, clearly state the cluster appears ready for upgrade.

## TL;DR
- **Current Version**: 4.21.4
- **Available Updates**: [TOTAL count, e.g., "6 updates available"]
- **Latest Update**: [Version with channels, e.g., "4.21.4 (stable-4.21, fast-4.21)"]
- **Update Channel**: [Current channel, e.g., "stable-4.21"]
- **Channel Options**: [Available channels for current version]
- **Capabilities**: [Count enabled/disabled, e.g., "5 enabled, 2 disabled (baremetal, insights)"]
- **Initial Version**: [From history, e.g., "4.20.0 (Jan 2026)"]
- **Last Upgrade**: [Most recent completed upgrade with date]
- **Cincinnati Health**: [Update service status, e.g., "Default service healthy (RetrievedUpdates=True, 6 hours ago)" or "Custom upstream: URL (status)"]
- **Upgrade Blocked**: [Yes/No - based on Upgradeable=False if present, Failing=True, or operator health]
- **Upgrade Blockers**: [specific reason from Upgradeable=False message, or Failing condition, or degraded operators]
- **Unhealthy ClusterOperators**: [count and names if any]
- **User Workload PDBs**: [count of problematic NON-OpenShift PDBs]
- **Degraded MCPs**: [count and names if any]
- **Node Issues**: [count of NotReady nodes if any]
- **Configuration Issues**: [any problematic overrides or settings]
- **Recommendation**: [Proceed with upgrade | Address specific issues first | Consider channel change]
</output_format>
