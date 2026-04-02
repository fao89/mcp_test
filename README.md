# OpenShift Cluster Update Prompt Refinement Repository

This repository contains test scenarios and tooling for refining and testing OpenShift cluster update analysis prompts using the MCP (Model Context Protocol) service.

## Overview

The repository provides a structured approach to test different OpenShift cluster upgrade scenarios against the MCP service to ensure accurate analysis and recommendations. Each directory represents a specific cluster state or upgrade scenario with real cluster data and expected analysis outcomes.

## Repository Structure

```
├── README.md                     # This file
├── mcp-client.sh                 # MCP service client script
├── process_all_dirs.sh           # Batch processing script
├── samples/                      # Sample data (excluded from processing)
├── precheck/                     # Pre-upgrade analysis scenario
│   ├── input.md                  # Analysis prompt/instructions
│   ├── clusterversion.yaml       # Cluster version data
│   ├── clusteroperators.yaml     # Cluster operators status
│   └── output.md                 # Generated analysis response
├── precheck-specific/            # Specific pre-upgrade checks
├── progress/                     # Upgrade progress monitoring
├── troubleshoot/                 # Upgrade troubleshooting scenario
└── no-updates/                   # No available updates scenario
```

## Test Scenarios

### 1. **precheck** - Pre-Upgrade Analysis
- **Purpose**: Comprehensive cluster health check before upgrades
- **Focus**: Available updates, operator health, upgrade readiness
- **Data**: Cluster with multiple available updates

### 2. **precheck-specific** - Targeted Pre-Checks
- **Purpose**: Specific upgrade prerequisite validation
- **Focus**: Targeted analysis for particular upgrade paths
- **Data**: Cluster with specific configuration concerns

### 3. **progress** - Upgrade Progress Monitoring
- **Purpose**: Analysis during active upgrade process
- **Focus**: Tracking upgrade progress, identifying issues
- **Data**: Cluster in upgrade progress state

### 4. **troubleshoot** - Upgrade Issue Resolution
- **Purpose**: Diagnosing and resolving upgrade problems
- **Focus**: Failed/stuck upgrades, operator issues
- **Data**: Cluster with upgrade-blocking issues

### 5. **no-updates** - Current State Analysis
- **Purpose**: Analysis when no updates are available
- **Focus**: Cluster health without update context
- **Data**: Cluster at latest version in channel

## Usage

### Prerequisites

- OpenShift CLI (`oc`) configured and authenticated
- Access to OpenShift Lightspeed MCP service
- Required tools: `curl`, `jq`, `bash`

### Processing All Scenarios

Run the batch processing script to analyze all scenarios:

```bash
./process_all_dirs.sh
```

This will:
1. Initialize connection to the MCP service
2. Process each directory with its input prompt and cluster data
3. Generate analysis responses in `output.md` files
4. Extract only the response content (not JSON metadata)

### Processing Individual Scenarios

For single scenario analysis:

```bash
# Example: Process precheck scenario
./mcp-client.sh --quiet query "$(cat precheck/input.md)

<attachments>
<attachment name=\"clusterversion.yaml\" type=\"yaml\">
$(cat precheck/clusterversion.yaml)
</attachment>

<attachment name=\"clusteroperators.yaml\" type=\"yaml\">
$(cat precheck/clusteroperators.yaml)
</attachment>
</attachments>" | jq -r '.response' > precheck/output.md
```

### Interactive Testing

Use the MCP client interactively:

```bash
./mcp-client.sh interactive
```

## File Formats

### input.md
Contains the analysis prompt with:
- Constraints and requirements
- Language validation rules
- Analysis focus areas
- Output format specifications

### clusterversion.yaml
Real OpenShift ClusterVersion resource data including:
- Current version information
- Available updates
- Update channel configuration
- Cluster capabilities

### clusteroperators.yaml
Real OpenShift ClusterOperator resources showing:
- Operator health status
- Available/Progressing/Degraded states
- Version information
- Operational messages

### output.md
Generated analysis containing:
- **Summary**: Comprehensive cluster analysis
- **TL;DR**: Key findings and recommendations
- Specific findings based on scenario type

## Development Workflow

1. **Add New Scenario**:
   - Create directory with descriptive name
   - Add `input.md` with analysis requirements
   - Include real `clusterversion.yaml` and `clusteroperators.yaml`
   - Test with `./mcp-client.sh`

2. **Refine Prompts**:
   - Modify `input.md` constraints and requirements
   - Re-run analysis to validate improvements
   - Compare outputs across scenarios

3. **Validate Responses**:
   - Review `output.md` for accuracy
   - Ensure language compliance
   - Verify technical correctness

## MCP Client Features

The `mcp-client.sh` script provides:
- Automatic pod discovery and port forwarding
- Authentication handling
- Health checks
- Language testing capabilities
- Interactive and batch modes
- JSON response extraction

## Quality Assurance

Each scenario tests:
- **Accuracy**: Correct analysis of real cluster data
- **Completeness**: All relevant issues identified
- **Clarity**: Clear, actionable recommendations
- **Consistency**: Standardized output format

## Contributing

1. Ensure all new scenarios include real, representative cluster data
2. Test prompts thoroughly before committing
3. Validate output quality and format consistency
4. Update this README when adding new scenario types

## Notes

- The `samples/` directory is excluded from batch processing
- All cluster data should be sanitized but representative
- Focus on real-world upgrade scenarios and edge cases
- Maintain consistent analysis quality across all scenarios
