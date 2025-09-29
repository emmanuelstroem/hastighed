# Implementation Plan: Query and Document GPKG Table Structure Schema

**Branch**: `007-feature-query-and` | **Date**: 2024-12-19 | **Spec**: [link]
**Input**: Feature specification from `/specs/007-feature-query-and/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Create a Python script to analyze GPKG file schemas and document the table structures, focusing on maxspeeds, street names, hazards, and traffic surveillance data. The script will examine existing GPKG files (Denmark, Sweden) to understand the common schema structure and generate comprehensive documentation.

## Technical Context
**Language/Version**: Python 3.9+, Swift 6.x  
**Primary Dependencies**: sqlite3, geopandas, fiona, shapely, pandas  
**Storage**: GPKG files (denmark.gpkg, sweden.gpkg)  
**Testing**: pytest  
**Target Platform**: Cross-platform (Python), iOS 17+ (Swift integration)  
**Project Type**: analysis tool + mobile integration  
**Performance Goals**: Schema analysis < 1 second, documentation generation < 5 seconds  
**Constraints**: Offline analysis, standard GPKG format compliance  
**Scale/Scope**: 2-3 GPKG files, comprehensive schema documentation

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Core Principles Compliance
- ✅ **Safety & Focus First**: Clear documentation for safe data access
- ✅ **Offline-First by Default**: Local GPKG file analysis
- ✅ **Test-First (Non-Negotiable)**: Python tests for schema analysis
- ✅ **Performance & Efficiency**: Fast schema queries and documentation
- ✅ **Privacy & Minimal Data**: Only analyze schema, no data extraction
- ✅ **Simplicity & Clarity**: Clear Python script with documented output
- ✅ **Observability & Transparency**: Detailed schema documentation
- ✅ **Single-Responsibility Functions**: Separate functions for each analysis task
- ✅ **Build Integrity**: Python script must run successfully
- ✅ **Platform Currency**: Modern Python libraries and Swift integration

### Quality Gates
- ✅ **Tests**: Python tests for schema analysis functions
- ✅ **Performance**: Fast schema analysis and documentation generation
- ✅ **Offline**: Local GPKG file analysis without network dependency
- ✅ **Simplicity**: Clear Python script with single responsibility functions
- ✅ **Build**: Python script must execute successfully
- ✅ **Functions**: Single responsibility for each analysis function

## Project Structure

### Documentation (this feature)
```
specs/007-feature-query-and/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Analysis tool
scripts/
├── gpkg_schema_analyzer.py    # Main Python script
├── requirements.txt           # Python dependencies
└── test_schema_analyzer.py    # Python tests

# Mobile integration
hastighed/
├── Models/
│   └── GpkgSchemaModels.swift # Schema data models
├── Services/
│   └── GpkgSchemaService.swift # Schema query service
└── Resources/
    └── gpkg_schema.json       # Generated schema documentation
```

**Structure Decision**: Analysis tool + mobile integration (Hybrid approach)

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - GPKG file structure and standard schema patterns
   - Python libraries for GPKG analysis (geopandas, fiona, sqlite3)
   - Common table naming conventions for speed limits, streets, hazards
   - Schema documentation formats and best practices

2. **Generate and dispatch research agents**:
   ```
   Task: "Research GPKG file structure and standard schema patterns"
   Task: "Find Python libraries for GPKG analysis and spatial data"
   Task: "Research common table naming conventions for road data"
   Task: "Find schema documentation best practices and formats"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - GpkgSchemaInfo entity for complete schema information
   - TableDefinition entity for individual table structures
   - ColumnDefinition entity for column metadata
   - SampleDataQuery entity for example queries

2. **Generate API contracts** from functional requirements:
   - Python script interface for schema analysis
   - Swift service interface for schema queries
   - Documentation generation interface
   - Output OpenAPI/JSON schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - Python tests for schema analysis functions
   - Swift tests for schema service integration
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Schema analysis scenarios for each GPKG file
   - Documentation generation scenarios
   - Integration scenarios with mobile app

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh cursor` for your AI assistant
   - Add GPKG schema analysis context
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each analysis function → Python implementation task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Python script before Swift integration
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 15-20 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

No violations identified - approach follows constitutional principles.

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*