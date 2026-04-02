# OpenShift Cluster Upgrade Pre-Check Analysis

<constraints>
- YOU SHOULD ALWAYS CALL THE TOOLS TO GET THE INFORMATION. YOU SHOULD NEVER TREAT DATA FROM EXAMPLES AS REAL DATA.
- YOU SHOULD ALWAYS REFERENCE REAL DATA FROM TOOL CALLS. IF REAL DATA IS NOT AVAILABLE, NOTIFY THE USER AND REFUSE TO ANSWER USING INCORRECT DATA BUT DO NOT USE PLACEHOLDER OR DUMMY DATA.
- Analyze ONLY the actual ClusterVersion data provided in the attachments
- Report SPECIFIC details from the actual conditions and messages
- ONLY OUTPUT the Summary and TL;DR sections
- Be specific about the source of any information identified
- CRITICAL: When counting available updates, count ALL array elements in status.availableUpdates
</constraints>

<context>
This is a pre-upgrade analysis for OpenShift cluster upgrade from 4.21.4 to 4.21.7. You have complete cluster data including ClusterVersion and all ClusterOperator resources to analyze the feasibility and safety of this specific upgrade.
</context>

<critical_analysis_requirements>

1. **Target Version Verification** (PRIORITY):
   - Look in status.availableUpdates array for 4.21.7
   - If found, extract its channels, url, and image information
   - If NOT found, report "4.21.7 is not available for upgrade"

2. **Cluster Upgrade Readiness**:
   - Check status.conditions for type="Upgradeable" (may not exist)
     * If Upgradeable=False, report the specific reason - this blocks upgrades
   - Check status.conditions for type="Failing"
     * If Failing=True, report details - this indicates problems
   - Check status.conditions for type="Available"
     * If Available=False, report cluster operational issues

3. **ClusterOperator Health Check**:
   - Check ClusterOperator resources for Available=False, Degraded=True, or Upgradeable=False
   - Report specific operator names and their issues
   - Focus on operators that would block upgrades

4. **Current Cluster Configuration**:
   - Extract spec.channel (current update channel)
   - Extract spec.clusterID
   - Check if spec.upstream is configured (custom Cincinnati server)
   - Note status.conditions RetrievedUpdates condition

5. **User Workload PDB Analysis**:
   - Check PodDisruptionBudgets in user namespaces (NOT openshift-* or kube-*)
   - Flag problematic PDBs with restrictive settings
   - If no issues, state "No problematic user workload PDBs found"

6. **Infrastructure Readiness**:
   - Check MachineConfigPool status for Degraded=True or paused pools
   - Check Node resources for NotReady conditions
   - Look for infrastructure problems

</critical_analysis_requirements>

<output_format>
## Summary

Provide a clear assessment based ONLY on data found in the ClusterVersion and ClusterOperator attachments. Be specific about:
- Whether 4.21.7 is available for upgrade (found in status.availableUpdates)
- Current cluster upgrade readiness (check Upgradeable=False, Failing=True, degraded operators)
- Any problematic USER WORKLOAD PDBs (not OpenShift system PDBs)
- Infrastructure issues that would prevent the upgrade to 4.21.7

If 4.21.7 is available and no critical issues are found, clearly state the cluster appears ready for upgrade to 4.21.7.
If 4.21.7 is not available, recommend the closest available version.

## TL;DR
- **Current Version**: 4.21.4
- **Target Version**: 4.21.7
- **Target Available**: [Yes/No - if 4.21.7 is in availableUpdates array]
- **Target Channels**: [Channels for 4.21.7 if available]
- **Current Channel**: [spec.channel from ClusterVersion]
- **Upgrade Blocked**: [Yes/No - check Upgradeable=False, Failing=True, operator issues]
- **Upgrade Blockers**: [Specific blocking conditions if any]
- **Unhealthy ClusterOperators**: [Count and names if any]
- **User Workload PDBs**: [Count of problematic non-OpenShift PDBs]
- **Infrastructure Issues**: [MCP/Node problems if any]
- **Recommendation**: [Proceed with upgrade to 4.21.7 | Address issues first | Target not available - use X.X.X instead]
</output_format>
