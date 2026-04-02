# OpenShift Cluster Health Assessment

<constraints>
- YOU SHOULD ALWAYS CALL THE TOOLS TO GET THE INFORMATION. YOU SHOULD NEVER TREAT DATA FROM EXAMPLES AS REAL DATA.
- YOU SHOULD ALWAYS REFERENCE REAL DATA FROM TOOL CALLS. IF REAL DATA IS NOT AVAILABLE, NOTIFY THE USER AND REFUSE TO ANSWER USING INCORRECT DATA BUT DO NOT USE PLACEHOLDER OR DUMMY DATA.
- Assess ONLY the actual cluster state from provided data
- Distinguish between system health and user workload issues
- Provide actionable recommendations for administrators
- ONLY OUTPUT the Summary and TL;DR sections
</constraints>

<context>
Health assessment for OpenShift cluster running 4.21.7 with no available updates. You have complete cluster data including ClusterVersion and all ClusterOperator resources for comprehensive health analysis.
Focus on operational health and readiness for future updates.
</context>

<health_assessment_requirements>

1. **Current Version and Update Status Analysis**:
   - Extract and confirm current version from status.desired.version matches 4.21.7
   - Verify status.availableUpdates array is empty (confirming no updates available)
   - Check status.conditions for RetrievedUpdates=True (confirms update service is working)
   - Analyze why no updates are available (end of channel, latest version, etc.)

2. **Cluster Capabilities Configuration Assessment**:
   - Extract enabled capabilities from status.capabilities.enabledCapabilities
   - Extract known capabilities from status.capabilities.knownCapabilities
   - Identify disabled capabilities (known but not enabled)
   - Assess capability configuration health and consistency
   - Check spec.capabilities.baselineCapabilitySet and additionalEnabledCapabilities

3. **Update Service and Channel Health**:
   - Check spec.upstream (if configured) or note "using default Red Hat update service"
   - Verify status.conditions for type="RetrievedUpdates" status and timestamp
   - Confirm update service connectivity is working despite no available updates
   - Current channel from spec.channel
   - Cluster ID for telemetry (spec.clusterID)
   - Signature verification status (spec.signatureStores if present, otherwise default stores)

4. **Cluster Version History Context**:
   - Extract initial cluster version from status.history (first entry)
   - Identify upgrade path from history entries
   - Last completed upgrade and timeframe
   - Total cluster age and upgrade frequency
   - Historical upgrade success pattern

5. **System Component Health** (Using Official OpenShift Standards):
   - **Available=False**: Component requires immediate administrator intervention
   - **Degraded=True**: Component doesn't match desired state, may have lower quality of service
   - **Progressing=True with errors**: Component stuck rolling out changes
   - **Upgradeable=False**: Component explicitly blocks minor upgrades until resolved
   - Verify core platform operators (console, authentication, ingress, etc.) are healthy
   - Check ClusterVersion status.conditions for overall cluster health
   - Report specific operator names and their condition messages

6. **Future Update Readiness Assessment**:
   - Check status.conditions for type="Upgradeable" (OPTIONAL condition)
     * If Upgradeable=False, this IS an upgrade blocker for future updates - report reason
     * If Upgradeable=True, missing, or Unknown - future upgrades are allowed
   - Check status.conditions for type="Failing"
     * If Failing=True, this indicates cluster issues that must be resolved
   - Review spec.overrides for any unmanaged components that might block future upgrades
   - Identify maintenance items to address proactively
   - User workload PDB analysis for potential upgrade blockers

7. **Operational Health and Recommendations**:
   - Identify issues that affect user applications
   - Focus on problems that cluster administrators can/should address
   - Provide specific, actionable guidance for maintaining cluster health
   - Distinguish from normal system maintenance activities
   - Avoid recommendations for normal system behavior

</health_assessment_requirements>

<output_format>
## Summary

**Overall Health Status**
[Assessment based on actual cluster state data]

**System Component Status**
- **Core Services**: [List core platform operators and their health status]
- **Degraded Operators**: [Any operators with Available=False or Degraded=True]
- **Progressing Operators**: [Operators currently updating or progressing]
- **Infrastructure**: [Overall cluster-level status and configuration]

**Administrator Action Items**
- **Immediate**: [Issues requiring prompt attention]
- **Maintenance**: [Items to address during maintenance windows]
- **Monitoring**: [Things to watch for trends]

**Future Update Readiness**
[Assessment of readiness for next OpenShift updates]

## TL;DR
- **Overall Status**: [Healthy | Minor issues | Attention needed]
- **System Health**: [Count of healthy vs degraded operators]
- **Core Platform**: [Status of essential operators: console, authentication, ingress, etc.]
- **Degraded Components**: [Count and names of any unhealthy operators]
- **User Impact**: [Any operator issues affecting workloads]
- **Action Items**: [Count of items needing administrator attention]
- **Update Readiness**: [Ready | Operator issues need resolution]
- **Next Review**: [Recommended reassessment timeframe]
</output_format>
