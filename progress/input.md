# OpenShift Cluster Upgrade Progress Monitor

<constraints>
- YOU SHOULD ALWAYS CALL THE TOOLS TO GET THE INFORMATION. YOU SHOULD NEVER TREAT DATA FROM EXAMPLES AS REAL DATA.
- YOU SHOULD ALWAYS REFERENCE REAL DATA FROM TOOL CALLS. IF REAL DATA IS NOT AVAILABLE, NOTIFY THE USER AND REFUSE TO ANSWER USING INCORRECT DATA BUT DO NOT USE PLACEHOLDER OR DUMMY DATA.
- Monitor ONLY actual upgrade progress from ClusterVersion data
- Report specific progress indicators and timelines
- Identify potential issues early with conservative recommendations
- ONLY OUTPUT the Summary and TL;DR sections
</constraints>

<context>
Monitor upgrade progress from 4.21.4 to 4.21.7. You have complete cluster data including ClusterVersion and all ClusterOperator resources to analyze upgrade progress and detect issues.
Focus on detecting issues early while avoiding false alarms.
</context>

<progress_monitoring_requirements>

1. **Upgrade State Verification**:
   - Confirm spec.desiredUpdate.version matches 4.21.7
   - Check status.conditions for type="Progressing" with specific progress details
   - Verify no Failing=True conditions are present

2. **Component Progress Tracking** (CRITICAL - Accurate Version Analysis):
   - For EACH ClusterOperator resource, you MUST extract the current operator version:
     * Find the entry in status.versions array where name="operator"
     * Use the "version" field from that entry as the current operator version
     * If no "operator" entry exists, check for the highest version among all entries
   - Compare each operator's current version with the target version 4.21.7
   - **Updated Operators**: Operators where current version equals 4.21.7
     * Example: operator version "4.21.3" when target is "4.21.3"
   - **Updating Operators**: Operators where current version < 4.21.7 AND status.conditions[type="Progressing"].status = "True"
     * Example: operator version "4.21.0" with Progressing=True when target is "4.21.3"
   - **Pending Operators**: Operators where current version < 4.21.7 AND status.conditions[type="Progressing"].status = "False"
     * Example: operator version "4.21.0" with Progressing=False when target is "4.21.3"
   - **Failed Operators**: Operators where status.conditions[type="Available"].status = "False" OR status.conditions[type="Degraded"].status = "True"
   - IMPORTANT: Do NOT report "None" unless you have verified ALL operators are at the target version
   - Count each category and list specific operator names with their current versions in each group
   - Calculate upgrade completion percentage: (Updated Operators / Total Operators) * 100

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

**Component Status**
- **Updated Operators**: [Count and list of operators at target version 4.21.7]
  * Example: "console (4.21.3), authentication (4.21.3)"
- **Updating Operators**: [Count and list of operators with current version < 4.21.7 AND Progressing=True]
  * Example: "ingress (4.21.0 → 4.21.3, Progressing=True)"
- **Pending Operators**: [Count and list of operators with current version < 4.21.7 AND Progressing=False]
  * Example: "machine-config (4.21.0, waiting for 4.21.3), network (4.21.0, waiting for 4.21.3)"
- **Failed Operators**: [Count and list of operators with Available=False OR Degraded=True]

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
- **Updated Components**: [Count of operators at 4.21.7 vs total]
- **Pending Components**: [Count of operators still at older versions - list specific operator names and versions]
- **Historical Comparison**: [How current upgrade compares to previous ones]
- **Issues**: [Any problems requiring attention]
- **ETA**: [Calculate: remaining_time based on current progress rate, format as "~XX minutes" or "~X hours"]
- **Action Required**: [Continue monitoring | Investigate delays | No action needed]
</output_format>
