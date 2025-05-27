# IkiWiki to GitHub Wiki Migration Plan

This document outlines a comprehensive plan for migrating the Tails documentation from IkiWiki to GitHub Wiki format.

## Executive Summary

The Tails wiki currently uses IkiWiki with 50+ language translations, custom styling, and complex content organization. Migrating to GitHub Wiki presents significant challenges but offers benefits in terms of platform integration and simplified maintenance.

## Major Challenges & Solutions

### 1. Translation System
**Current**: IkiWiki uses gettext PO files for 50+ languages
**GitHub Wiki**: No built-in translation support

**Solution Options**:
- **Option A**: Separate wiki per language (tails.wiki, tails-fr.wiki, etc.)
- **Option B**: Language prefixes in page names (fr-about, es-about)
- **Option C**: Single wiki with language sections (/fr/, /es/)
- **Recommended**: Option C with automated sync tools

### 2. Content Structure
**Current**: Hierarchical directory structure with index pages
**GitHub Wiki**: Flat structure with sidebar navigation

**Solution**:
- Flatten directory structure using prefixes (doc-about-features)
- Generate comprehensive sidebar navigation
- Maintain URL redirects for backward compatibility

### 3. IkiWiki Directives
**Current**: Custom directives like [[!meta]], [[!img]], [[!toc]]
**GitHub Wiki**: Standard GitHub Flavored Markdown

**Conversion Required**:
```
[[!meta title="About"]] → # About (at top of page)
[[!img file.png]] → ![](file.png)
[[!toc levels=2]] → GitHub auto-generates TOC
[[!inline pages="..."]] → Manual content inclusion needed
```

### 4. Asset Management
**Current**: Images and files in /lib/ directories
**GitHub Wiki**: Upload through web interface or git

**Solution**:
- Create asset repository (tails-wiki-assets)
- Use raw.githubusercontent.com URLs
- Automate asset upload process

## Migration Strategy

### Phase 1: Analysis & Preparation (Week 1-2)

1. **Content Inventory**
   - Count pages per language
   - Identify complex IkiWiki features used
   - Map current URL structure

2. **Tool Development**
   - IkiWiki to Markdown converter
   - Translation file processor
   - Asset migration script

3. **Pilot Migration**
   - Test with small documentation section
   - Validate conversion quality
   - Refine tools based on results

### Phase 2: Content Conversion (Week 3-4)

1. **Automated Conversion**
   ```bash
   # Pseudo-code for conversion process
   for page in wiki/src/**/*.mdwn; do
     convert_ikiwiki_to_gfm "$page"
     extract_metadata "$page"
     process_images "$page"
   done
   ```

2. **Manual Review Required For**:
   - Complex HTML pages
   - Custom styling
   - Interactive elements
   - Inline includes

3. **Translation Processing**
   ```bash
   # Convert PO files to markdown
   for po in wiki/src/**/*.po; do
     po_to_markdown "$po"
     organize_by_language "$po"
   done
   ```

### Phase 3: Structure Reorganization (Week 5)

1. **Flatten Hierarchy**
   ```
   /doc/about/features.mdwn → doc-about-features.md
   /install/windows.mdwn → install-windows.md
   ```

2. **Generate Navigation**
   - Create _Sidebar.md with full navigation
   - Language-specific sidebars
   - Breadcrumb alternatives

3. **URL Mapping**
   - Create redirect map
   - Set up nginx redirects
   - Update internal links

### Phase 4: GitHub Setup (Week 6)

1. **Repository Structure**
   ```
   tails/tails.wiki (main English wiki)
   tails/tails-wiki-assets (shared assets)
   tails/tails-wiki-translations (automated sync)
   ```

2. **Automation Setup**
   - GitHub Actions for translation sync
   - Asset CDN configuration
   - Search indexing

### Phase 5: Migration Execution (Week 7)

1. **Content Upload**
   - Use GitHub API for bulk upload
   - Preserve git history where possible
   - Verify all content migrated

2. **Quality Assurance**
   - Link checking
   - Image verification
   - Translation completeness

### Phase 6: Cutover (Week 8)

1. **DNS/Redirect Setup**
2. **Documentation Update**
3. **Announcement**

## Technical Implementation

### Conversion Script Structure

```python
# ikiwiki_to_github_wiki.py
class IkiWikiConverter:
    def convert_page(self, source_path):
        # Read IkiWiki content
        # Parse directives
        # Convert to GitHub Markdown
        # Handle special cases
        # Return converted content
        
    def process_translations(self, po_file):
        # Extract translations
        # Convert to markdown
        # Organize by language
        
    def migrate_assets(self, asset_path):
        # Upload to GitHub
        # Update references
        # Return new URLs
```

### GitHub Wiki Structure

```
Home.md
_Sidebar.md
_Footer.md

# English pages
doc-about.md
doc-about-features.md
install-windows.md

# French pages (example)
fr/
  doc-about.md
  doc-about-features.md
  install-windows.md
```

### Translation Sync Workflow

```yaml
# .github/workflows/sync-translations.yml
name: Sync Wiki Translations
on:
  push:
    paths:
      - 'wiki-translations/**'
  schedule:
    - cron: '0 2 * * 1' # Weekly

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout translations
      - name: Convert PO to Markdown
      - name: Update wiki pages
      - name: Commit changes
```

## Feature Comparison & Mitigation

| IkiWiki Feature | GitHub Wiki | Mitigation Strategy |
|----------------|-------------|-------------------|
| PO file translations | None | Automated conversion + sync |
| Hierarchical structure | Flat | Prefix naming + sidebar |
| Custom directives | GFM only | Pre-conversion processing |
| Build-time processing | Runtime only | GitHub Actions automation |
| Inline includes | Manual only | Convert to full content |
| Custom CSS | Limited | Inline styles where critical |
| Deterministic builds | Git-based | Git commit hashes |
| Local preview | Web preview | Local git wiki clone |

## Benefits of Migration

1. **Platform Integration**
   - Unified GitHub ecosystem
   - Better issue/PR integration
   - Simplified contributor workflow

2. **Reduced Complexity**
   - No build process required
   - Standard Markdown format
   - Native GitHub features

3. **Better Collaboration**
   - Web-based editing
   - Built-in revision history
   - Pull request workflow for wikis

## Risks & Mitigation

### Risk 1: Loss of Translation Workflow
**Mitigation**: Build robust automation tools for PO→MD conversion

### Risk 2: Broken Links
**Mitigation**: Comprehensive redirect mapping and link checking

### Risk 3: Feature Loss
**Mitigation**: Document workarounds for missing features

### Risk 4: Large Migration Effort
**Mitigation**: Phased approach with rollback capability

## Alternative Approaches

### 1. GitHub Pages with Jekyll
- Pros: More control, better translation support
- Cons: Still requires build process

### 2. Docusaurus
- Pros: Modern documentation platform, i18n support
- Cons: Different from GitHub ecosystem

### 3. Keep IkiWiki with GitHub hosting
- Pros: No conversion needed
- Cons: Misses GitHub integration benefits

## Timeline Summary

- **Weeks 1-2**: Analysis and tool development
- **Weeks 3-4**: Content conversion
- **Week 5**: Structure reorganization  
- **Week 6**: GitHub setup
- **Week 7**: Migration execution
- **Week 8**: Cutover and go-live

**Total Duration**: 8 weeks

## Next Steps

1. Approve migration approach
2. Allocate development resources
3. Create detailed technical specifications
4. Begin tool development
5. Set up test environment

## Conclusion

While migrating from IkiWiki to GitHub Wiki presents challenges, particularly around translations and structure, the benefits of platform integration and simplified maintenance make it worthwhile. The proposed phased approach with robust tooling can ensure a successful migration while preserving content integrity and translation support.