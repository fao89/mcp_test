# OpenShift Cluster Upgrade Troubleshoot Analysis

<constraints>
- YOU SHOULD ALWAYS CALL THE TOOLS TO GET THE INFORMATION. YOU SHOULD NEVER TREAT DATA FROM EXAMPLES AS REAL DATA.
- YOU SHOULD ALWAYS REFERENCE REAL DATA FROM TOOL CALLS. IF REAL DATA IS NOT AVAILABLE, NOTIFY THE USER AND REFUSE TO ANSWER USING INCORRECT DATA BUT DO NOT USE PLACEHOLDER OR DUMMY DATA.
- Analyze ONLY the actual ClusterVersion data provided
- Report SPECIFIC failure details from the actual conditions and messages
- Provide conservative, investigation-focused remediation
- Focus on root cause identification, not aggressive fixes
- ONLY OUTPUT the Summary and TL;DR sections
</constraints>

<context>
Troubleshoot upgrade issues for cluster attempting to go from 4.21.4 to 4.21.7. You have complete cluster data including ClusterVersion and all ClusterOperator resources to diagnose upgrade failures.
This prompt is used when upgrade failures or component degradation is detected.
</context>

<failure_analysis_requirements>

1. **Upgrade Failure Root Cause**:
   - Check status.conditions for type="Failing" with status="True"
   - Extract the EXACT reason and message from the Failing condition
   - Check status.history for failed upgrade attempts and their specific errors
   - Identify which component or process is actually failing

2. **ClusterOperator Failure Analysis**:
   - Check each ClusterOperator for Available=False, Degraded=True, or Progressing=True with errors
   - Report SPECIFIC operator names and their condition messages
   - Look for operators stuck in upgrade states with error details
   - Identify operators that are blocking the overall cluster upgrade

3. **Cluster-Level Failure Analysis**:
   - Check ClusterVersion status.conditions for Failing=True with specific error messages
   - Review status.conditions for Degraded or Invalid conditions
   - Look for specific failure reasons in condition messages and status

4. **Node and Infrastructure Issues**:
   - Check Node resources for NotReady conditions
   - Identify nodes with scheduling issues or resource constraints
   - Look for infrastructure problems affecting the upgrade

5. **MachineConfigPool Issues**:
   - Check for Degraded=True, spec.paused=true, or observedGeneration ≠ metadata.generation
   - These can cause upgrade failures and node configuration problems

6. **Historical Failure Context**:
   - Previous upgrade attempts from status.history
   - Compare current failure with historical upgrade patterns
   - Identify recurring issues or new problems
   - Duration and frequency of past upgrade attempts

7. **Update Target Analysis for Failures**:
   - Failed target version from status.desired.version
   - Release metadata and known issues from status.desired.url
   - Target channel information from status.desired.channels
   - Validate if target version is still available and supported

8. **Cincinnati and Update Service Analysis**:
   - Update service configuration (spec.upstream if custom, otherwise default Red Hat service)
   - Recent update retrieval status from RetrievedUpdates condition
   - Verify availableUpdates is populated (indicates service connectivity)
   - Signature verification status (spec.signatureStores if custom, otherwise default Red Hat stores)
   - Network connectivity issues affecting update process

9. **Conservative Remediation Approach**:
   - Focus on investigation and monitoring first
   - Suggest checking logs and status before taking action
   - Avoid aggressive suggestions like "restart operators" unless clearly needed
   - Recommend escalation paths for complex issues
   - Consider rollback strategies based on failure severity

</failure_analysis_requirements>

<output_format>
## Summary

**Root Cause Analysis**
Based on the ClusterVersion data:
- **Current Version**: 4.21.4
- **Target Version**: 4.21.7
- **Failure Type**: [Extract from actual Failing condition reason]
- **Specific Error**: [Quote the actual failure message from conditions]

**Component Analysis**
- **Failed ClusterOperators**: [List specific operators with Available=False, Degraded=True, or failing conditions]
- **Stuck ClusterOperators**: [List operators stuck in Progressing=True with error messages]
- **Affected Services**: [Impact on cluster functionality based on failed operators]

**Failed Upgrade Context**
- **Target Version**: [From status.desired.version with metadata]
- **Release Information**: [Target release details and known issues from status.desired.url]
- **Upgrade Path**: [Source → Target version progression]
- **Target Availability**: [Verify target version is still in available updates]

**Historical Failure Analysis**
- **Previous Attempts**: [Recent upgrade attempts from status.history]
- **Failure Pattern**: [Recurring vs new failure based on history]
- **Last Successful Upgrade**: [Most recent completed upgrade for comparison]
- **Cluster Stability**: [Overall upgrade success rate and patterns]

**Update Service Health**
- **Service Configuration**: [spec.upstream if custom, otherwise "Default Red Hat service"]
- **Cincinnati Status**: [RetrievedUpdates condition status and message]
- **Last Update Check**: [Recent update retrieval timestamp from RetrievedUpdates]
- **Available Updates**: [Confirm availableUpdates array is populated]
- **Connectivity Issues**: [Network or authentication problems affecting updates]

**Investigation Steps**
1. [First diagnostic step based on actual failure type]
2. [Second diagnostic step]
3. [Log locations to check]

**Recovery Actions** (Conservative Approach)
1. [Investigation-focused first step]
2. [Monitoring and validation steps]
3. [When to escalate to support]

## TL;DR
- **Failure Type**: [Specific failure reason from conditions]
- **Target Version**: [Failed upgrade target with release info]
- **Root Cause**: [Primary component or process failing]
- **Failed Components**: [Count and names of failed ClusterOperators]
- **Historical Pattern**: [Recurring failure vs new issue]
- **Last Success**: [Most recent completed upgrade for context]
- **Update Service**: [Cincinnati health, e.g., "Default service working (RetrievedUpdates=True)" or "Custom upstream failing"]
- **Node Issues**: [Count of NotReady nodes if any]
- **Infrastructure Problems**: [Any detected infrastructure issues]
- **MCP Issues**: [Count of degraded MachineConfigPools if any]
- **Next Steps**: [Conservative investigation approach]
- **Escalation**: [When to contact Red Hat support]
- **Recovery Time**: [Realistic estimate based on failure type]
</output_format>
