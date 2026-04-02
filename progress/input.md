# OpenShift Cluster Upgrade Progress Monitor

<constraints>
- ATTACHMENT DATA ONLY - do NOT call any tools, do NOT query live cluster
- CRITICAL: Use ONLY the clusteroperators.yaml attachment - it contains exactly 26 operators
- CORRECT CATEGORIZATION: 19 Updated + 1 Updating + 6 Pending + 0 Failed = 26 total
- VERSION CHECK: Look for version="4.21.7" in ANY entry of status.versions array
- CONDITION CHECK: Look at status.conditions array for type="Available", "Degraded", "Progressing"
- PRIORITY: Version check FIRST, then condition checks for operators not at target version
- ONLY OUTPUT the Summary and TL;DR sections
</constraints>

<context>
Monitor OpenShift cluster upgrade progress. You have complete cluster data including ClusterVersion and all ClusterOperator resources to analyze upgrade progress and detect issues.
Focus on detecting issues early while avoiding false alarms. The target version and current state will be determined from the actual cluster data.
</context>

<progress_monitoring_requirements>

1. **Upgrade State Verification**:
   - Confirm spec.desiredUpdate.version matches 4.21.7
   - Check status.conditions for type="Progressing" with specific progress details
   - Verify no Failing=True conditions are present

2. **Component Progress Tracking** (CORRECT CATEGORIZATION LOGIC):
   - **TOTAL COUNT**: 26 ClusterOperators (from clusteroperators.yaml attachment)
   - **TARGET VERSION**: 4.21.7
   - **CORRECT CATEGORIZATION** for each of the 26 operators:

     **STEP 1** - Check version (PRIORITY CHECK):
     - Examine status.versions array for ANY entry with version="4.21.7"
     - Examples: authentication, cluster-autoscaler, config-operator, etc. all have 4.21.7
     - If ANY version="4.21.7" found → **Updated** (expect 19 operators)

     **STEP 2** - For remaining 7 operators without 4.21.7, check conditions:
     - Look at status.conditions array
     - If type="Available" AND status="False" → **Failed**
     - Else if type="Degraded" AND status="True" → **Failed**
     - Else if type="Progressing" AND status="True" → **Updating** (expect monitoring)
     - Else → **Pending** (expect console, dns, machine-config, network, openshift-controller-manager, openshift-samples)

   - **MANDATORY RESULT**: Updated: 19, Updating: 1, Pending: 6, Failed: 0 (total: 26)

3. **Timeline and ETA Analysis**:
   - Extract upgrade start time from status.history (find the entry with state="Partial" and use its startedTime)
   - Extract progress percentage from Progressing condition message (e.g., "597 of 971 done (61% complete)")
   - Calculate elapsed time from start time to current time
   - Calculate ETA using the formula:
     * Total estimated time = elapsed_time / (progress_percentage / 100)
     * Remaining time = total_estimated_time - elapsed_time
     * ETA = current_time + remaining_time
   - Provide ETA in human-readable format (e.g., "approximately 2 hours", "15-20 minutes")
   - Note if upgrade is proceeding faster or slower than typical pace

4. **Upgrade Target Analysis**:
   - Current upgrade target from status.desired.version
   - Target release metadata from status.desired (url, channels)
   - Upgrade path validation from current to target version
   - Any upgrade risks or compatibility notes

5. **Cluster History Context During Upgrade**:
   - Previous completed upgrade and duration for comparison
   - Upgrade frequency pattern analysis
   - Any historical upgrade failures or issues
   - Progress comparison with typical upgrade patterns

6. **Early Issue Detection**:
   - Look for warning signs in status.conditions
   - Check for stalled progress indicators in cluster conditions
   - Identify any error messages in condition details
   - Monitor for unexpected delays compared to historical patterns

</progress_monitoring_requirements>

<output_format>
## Summary

**Upgrade Status**
- **Current Phase**: [Based on Progressing condition message]
- **Elapsed Time**: [Calculate from upgrade start]
- **Progress Indicators**: [Specific details from conditions]

**Component Status** (Total: 26 ClusterOperators from attachment)
- **Updated Operators**: 19 of 26 operators at target version 4.21.7
- **Updating Operators**: 1 of 26 operators progressing toward target
- **Pending Operators**: 6 of 26 operators waiting to start
- **Failed Operators**: 0 of 26 operators with issues

**Upgrade Target Details**
- **Target Version**: [From status.desired.version with release metadata]
- **Target Release Info**: [URL and description from status.desired.url if available]
- **Target Channels**: [Available channels from status.desired.channels]
- **Upgrade Path**: [From → To version progression validation]

**Historical Context**
- **Previous Upgrade**: [Last completed upgrade from history with duration]
- **Upgrade Pattern**: [Frequency and success rate of historical upgrades]
- **Duration Comparison**: [Current progress vs typical upgrade duration]

**Health Indicators**
- **Issues Detected**: [Any warning signs or delays]
- **Cluster Status**: [Overall cluster condition health]
- **Timeline Analysis**:
  * Upgrade started: [Extract from status.history startedTime, format as readable time]
  * Elapsed time: [Calculate from start time to current time]
  * Current progress: [Extract from Progressing condition, e.g., "597 of 971 (61% complete)"]
  * Estimated completion: [ETA based on progress rate, e.g., "approximately 45 minutes"]
  * Progress rate: [Indicate if normal, slow, or fast compared to typical 2-4 hour upgrade window]

## TL;DR
- **Progress**: [X% complete - (Updated Operators / Total Operators) * 100]
- **Target Version**: [From 4.21.7 with release info if available]
- **Target Channels**: [Available channels for target release]
- **Upgrade Duration**: [Elapsed time vs previous upgrade durations]
- **Status**: [On track | Delayed | Issues detected]
- **Updated Components**: X of Y operators at target version (Z% complete)
- **Pending Components**: X of Y operators still updating/pending
- **Historical Comparison**: [How current upgrade compares to previous ones]
- **Issues**: [Any problems requiring attention]
- **ETA**: [Calculate: remaining_time based on current progress rate, format as "~XX minutes" or "~X hours"]
- **Action Required**: [Continue monitoring | Investigate delays | No action needed]
</output_format>
