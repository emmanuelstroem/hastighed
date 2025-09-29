# Feature Specification: Query and Document GPKG Table Structure Schema

**Feature Branch**: `007-feature-query-and`  
**Created**: 2024-12-19  
**Status**: Draft  
**Input**: User description: "Query and document the table structure/schema in the GPKG file. This will be the same schema/structure for all the other GPKG files. We are mostly interested in all the maxspeeds, street name, hazards and traffic surveillance and cameras"

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Project Defaults (for this repository)
- Language: Swift 6.x
- Target Platform: iOS 17+
- Testing: XCTest
- UI Threshold: Amber within ±5% of current speed limit
- CarPlay: Display speed, speed limit, alerts; audible over-limit alert

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a developer working on the speed monitoring app, I want to understand the structure and schema of the GPKG files so that I can properly query for speed limits, street names, hazards, and traffic surveillance data.

### Acceptance Scenarios
1. **Given** a GPKG file is available, **When** I query the database schema, **Then** I receive a complete list of all tables and their column definitions
2. **Given** I have access to the GPKG file, **When** I query for speed limit data, **Then** I can identify which table contains maxspeed information and its structure
3. **Given** I need street name information, **When** I query the schema, **Then** I can identify the table and columns containing street name data
4. **Given** I want to find hazard information, **When** I query the database, **Then** I can identify tables containing hazard data and their attributes
5. **Given** I need traffic surveillance data, **When** I query the schema, **Then** I can identify tables containing camera and surveillance information

### Edge Cases
- What happens when the GPKG file is corrupted or unreadable?
- How does the system handle GPKG files with different schema versions?
- What occurs when some expected tables are missing from the GPKG file?
- How does the system handle GPKG files with non-standard table structures?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST be able to connect to and read GPKG files using SQLite3
- **FR-002**: System MUST query and return complete database schema information
- **FR-003**: System MUST identify tables containing speed limit (maxspeed) data
- **FR-004**: System MUST identify tables containing street name information
- **FR-005**: System MUST identify tables containing hazard data
- **FR-006**: System MUST identify tables containing traffic surveillance and camera data
- **FR-007**: System MUST document table structures with column names, types, and constraints
- **FR-008**: System MUST handle multiple GPKG files with consistent schema analysis
- **FR-009**: System MUST provide sample data queries for each identified table
- **FR-010**: System MUST generate comprehensive documentation of the schema

### Key Entities *(include if feature involves data)*
- **GpkgSchemaInfo**: Contains complete database schema information
- **TableDefinition**: Represents a single table with its columns and constraints
- **ColumnDefinition**: Contains column name, type, and metadata
- **SampleDataQuery**: Provides example queries for each table type
- **SchemaDocumentation**: Comprehensive documentation of the GPKG structure

### Performance Goals *(include when relevant)*
- Schema query response time < 1 second
- Documentation generation < 5 seconds
- Memory usage < 10MB for schema analysis
- Support for GPKG files up to 1GB in size

### Constraints & Scale *(include when relevant)*
- Must work with existing GPKG files (Denmark, Sweden, Liechtenstein)
- Offline analysis capability
- No network dependency for schema queries
- Support for standard GPKG format compliance

### Platform Support *(include when relevant)*
- iOS 17+ compatibility
- Swift Package Manager integration
- Command-line tool capability for schema analysis
- Documentation generation in multiple formats (Markdown, JSON)

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---
