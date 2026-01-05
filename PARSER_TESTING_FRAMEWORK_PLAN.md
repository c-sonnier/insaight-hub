# Parser Testing Framework Implementation Plan

## Executive Summary

This document outlines a plan to create a unified testing framework for all insurance document parsing jobs. The framework will allow any parser to run in "test mode" against local files, outputting structured JSON without database writes.

---

## Current State Analysis

### Existing Local Testing Implementations

| Parser | Has Local Testing? | Implementation |
|--------|-------------------|----------------|
| `AetnaParsePdfJob` | Yes | Full implementation with `manual`, `file_path`, `directory_path` options |
| `UnitedBackfillTotalEnrolledJob` | Yes | Simplified `file_path` option |
| All other parsers | No | Always require database document lookup |

### Problems with Current Approach

1. **Code Duplication**: Aetna parser has ~90 lines of duplicated logic for local file testing
2. **Inconsistent Output**: Each implementation produces different JSON structures
3. **No Standardization**: No shared way to add testing capability to existing parsers
4. **Manual Testing Friction**: Developers must modify code or copy/paste to test parsers locally

---

## Proposed Solution: `ParserTestable` Concern

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Parser Job                                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              include ParserTestable                        │  │
│  │                                                            │  │
│  │  perform(doc_id_or_nil, options = {})                     │  │
│  │    ├── options[:test_mode] = true                         │  │
│  │    │     └── route to test_mode_handler                   │  │
│  │    │           ├── options[:file_path]    → single file   │  │
│  │    │           └── options[:directory_path] → batch       │  │
│  │    └── normal mode                                        │  │
│  │          └── database operations as usual                 │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Parser implements:                                              │
│    - parse_document_content(file_path) → raw parsed data        │
│    - format_parsed_data(data)          → standardized hash      │
│    - parser_metadata                   → carrier info           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              ParserTestable Concern                              │
│                                                                  │
│  Provides:                                                       │
│    - test_mode_handler(options)                                 │
│    - process_single_file(file_path)                             │
│    - process_directory(directory_path)                          │
│    - generate_test_output(results)                              │
│    - write_json_results(data, output_path)                      │
│    - standardized_result_schema                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## JSON Output Schema

### Root Structure

```json
{
  "metadata": {
    "generated_at": "2024-12-28T10:30:00Z",
    "parser": "AetnaParsePdfJob",
    "carrier_id": 71,
    "carrier_name": "Aetna",
    "framework_version": "1.0"
  },
  "summary": {
    "total_files": 5,
    "successful": 4,
    "failed": 1,
    "processing_time_ms": 2340
  },
  "files": [
    { /* see File Result Schema */ }
  ]
}
```

### File Result Schema

```json
{
  "file": "proposal_12345.pdf",
  "path": "/path/to/proposal_12345.pdf",
  "success": true,
  "error": null,
  "processing_time_ms": 450,

  "document_details": {
    "effective_date": "2025-01-01",
    "group_name": "Acme Corp",
    "customer_number": "12345678",
    "file_type": "LF",
    "products": ["Medical", "Dental"],
    "proposal_type": "Underwritten Renewal",

    "_carrier_specific": {
      "isl_level": "$25,000",
      "asl_level": "125%",
      "surplus_return_type": "50%"
    }
  },

  "offers": [
    { /* see Offer Schema */ }
  ],

  "renewal_offers": {
    "current": [ /* offer objects */ ],
    "renewal": [ /* offer objects */ ]
  },

  "tags": ["Medical", "LF", "Renewal", "BBF"]
}
```

### Offer Schema

The offer schema is designed to be consistent across all carriers while allowing for carrier-specific extensions:

```json
{
  "rate_plan_mapping": "14012345",

  "rates": {
    "eo_rate": 450.00,
    "es_rate": 900.00,
    "ec_rate": 850.00,
    "ef_rate": 1350.00,
    "premium_total": 45000.00
  },

  "level_funded": {
    "isl_ded": "$25,000",
    "isl_coverage": "medical + rx",
    "asl_corridor": 0.125,
    "admin_rate": 45.00,
    "admin_total": 1125.00,
    "fixed_cost_percent": 0.65,
    "surplus_pay_option": "50% Admin Credit",
    "surplus_pay_month": "16th month"
  },

  "enrollment_counts": {
    "eo": 15,
    "es": 3,
    "ec": 4,
    "ef": 2,
    "total": 24
  },

  "age_rates": {
    "age_0_14": 250.00,
    "age_15": 275.00,
    "age_64_plus": 1200.00
  }
}
```

### Design Principles

1. **Core fields are always present**: `rate_plan_mapping`, `rates` object
2. **Optional sections omitted when empty**: Don't include `level_funded: {}` or `enrollment_counts: null`
3. **Carrier-specific data in dedicated section**: Use `document_details._carrier_specific` for non-standard fields
4. **Consistent naming**: Use snake_case, match existing Offer model attribute names where possible
5. **Explicit nulls for expected-but-missing**: If a field should exist but parsing failed, use `null`

---

## Implementation Plan

### Phase 1: Create the `ParserTestable` Concern

**File**: `lib/concerns/parser_testable.rb`

```ruby
# frozen_string_literal: true

module ParserTestable
  extend ActiveSupport::Concern

  FRAMEWORK_VERSION = "1.0"

  included do
    # Parsers must define these constants
    # CARRIER_ID = 71
    # CARRIER_NAME = "Aetna"  # optional, derived from CARRIER_ID if not set
  end

  class_methods do
    def test_file(file_path)
      new.perform(nil, { test_mode: true, file_path: file_path })
    end

    def test_directory(directory_path, pattern: "**/*.pdf")
      new.perform(nil, { test_mode: true, directory_path: directory_path, pattern: pattern })
    end
  end

  # ─────────────────────────────────────────────────────────────
  # Methods parsers MUST implement
  # ─────────────────────────────────────────────────────────────

  # Parse a local file and return raw extracted data
  # @param file_path [String] path to file
  # @return [Hash] raw parsed data (carrier-specific structure)
  def parse_file_content(file_path)
    raise NotImplementedError, "#{self.class.name} must implement #parse_file_content"
  end

  # Convert raw parsed data to standardized test output format
  # @param raw_data [Hash] output from parse_file_content
  # @return [Hash] standardized format matching Offer Schema
  def format_test_output(raw_data)
    raise NotImplementedError, "#{self.class.name} must implement #format_test_output"
  end

  # ─────────────────────────────────────────────────────────────
  # Methods parsers MAY override
  # ─────────────────────────────────────────────────────────────

  # Additional file extensions this parser can handle (default: pdf)
  def supported_extensions
    %w[pdf]
  end

  # Carrier name for metadata (derived from CARRIER_ID if not overridden)
  def carrier_name
    self.class.const_get(:CARRIER_NAME) rescue carrier_lookup(carrier_id)
  end

  def carrier_id
    self.class.const_get(:CARRIER_ID)
  end

  private

  # ─────────────────────────────────────────────────────────────
  # Test mode infrastructure (provided by concern)
  # ─────────────────────────────────────────────────────────────

  def handle_test_mode(options)
    start_time = Time.now
    results = []

    if options[:directory_path]
      pattern = options[:pattern] || "**/*.{#{supported_extensions.join(',')}}"
      files = Dir.glob(File.join(options[:directory_path], pattern))
    elsif options[:file_path]
      files = [options[:file_path]]
    else
      raise ArgumentError, "test_mode requires :file_path or :directory_path"
    end

    files.each do |file_path|
      results << process_test_file(file_path)
    end

    output = build_test_output(results, Time.now - start_time)
    write_test_results(output, options)
    output
  end

  def process_test_file(file_path)
    file_start = Time.now

    result = {
      file: File.basename(file_path),
      path: file_path,
      success: false,
      error: nil,
      processing_time_ms: nil
    }

    begin
      raw_data = parse_file_content(file_path)
      formatted = format_test_output(raw_data)
      result.merge!(formatted)
      result[:success] = true
    rescue => e
      result[:error] = "#{e.class}: #{e.message}"
      result[:error_backtrace] = e.backtrace.first(5)
    ensure
      result[:processing_time_ms] = ((Time.now - file_start) * 1000).round
    end

    result
  end

  def build_test_output(results, elapsed_time)
    {
      metadata: {
        generated_at: Time.now.iso8601,
        parser: self.class.name,
        carrier_id: carrier_id,
        carrier_name: carrier_name,
        framework_version: FRAMEWORK_VERSION
      },
      summary: {
        total_files: results.size,
        successful: results.count { |r| r[:success] },
        failed: results.count { |r| !r[:success] },
        processing_time_ms: (elapsed_time * 1000).round
      },
      files: results
    }
  end

  def write_test_results(output, options)
    output_dir = options[:output_path] || options[:directory_path] || File.dirname(options[:file_path])
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    filename = "#{self.class.name.underscore}_#{timestamp}_results.json"
    output_path = File.join(output_dir, filename)

    File.write(output_path, JSON.pretty_generate(output))

    puts "\n#{'='*60}"
    puts "Parser Test Results: #{self.class.name}"
    puts "#{'='*60}"
    puts "Output saved to: #{output_path}"
    puts "Total files: #{output[:summary][:total_files]}"
    puts "Successful: #{output[:summary][:successful]}"
    puts "Failed: #{output[:summary][:failed]}"
    puts "Processing time: #{output[:summary][:processing_time_ms]}ms"
    puts "#{'='*60}\n"

    output_path
  end

  def carrier_lookup(id)
    # Fallback carrier name lookup
    {
      5 => "Aetna",
      12 => "BCBS",
      65 => "United",
      71 => "Aetna",
      105 => "Humana",
      5770 => "All Savers"
    }[id] || "Unknown (#{id})"
  end
end
```

### Phase 2: Create Helper Module for Common Parsing Utilities

**File**: `lib/concerns/parser_utilities.rb`

```ruby
# frozen_string_literal: true

module ParserUtilities
  extend ActiveSupport::Concern

  # Common money/currency parsing
  def money_to_decimal(value)
    return nil if value.blank?
    value.to_s.gsub(/[$,\s]/, '').to_f
  end

  # Common date parsing with multiple format support
  def parse_date_flexible(date_string, patterns: nil)
    return nil if date_string.blank?
    return date_string if date_string.is_a?(Date)

    patterns ||= ["%m/%d/%Y", "%m/%d/%y", "%B %e, %Y", "%Y-%m-%d"]

    patterns.each do |pattern|
      begin
        return Date.strptime(date_string.to_s.strip, pattern)
      rescue ArgumentError
        next
      end
    end
    nil
  end

  # Standardize rate plan mapping format
  def normalize_rate_plan_mapping(rpm)
    return nil if rpm.blank?
    rpm.to_s
       .delete("-")
       .gsub(" RX ", " ")
       .gsub(/\s+/, " ")
       .strip
  end

  # Build standardized rates hash
  def build_rates_hash(eo:, es:, ec:, ef:, total: nil)
    {
      eo_rate: money_to_decimal(eo),
      es_rate: money_to_decimal(es),
      ec_rate: money_to_decimal(ec),
      ef_rate: money_to_decimal(ef),
      premium_total: money_to_decimal(total)
    }.compact
  end

  # Build level-funded data hash (only if present)
  def build_level_funded_hash(isl_ded: nil, isl_coverage: nil, asl_corridor: nil,
                               admin_rate: nil, admin_total: nil,
                               fixed_cost_percent: nil,
                               surplus_pay_option: nil, surplus_pay_month: nil)
    hash = {
      isl_ded: isl_ded,
      isl_coverage: isl_coverage,
      asl_corridor: asl_corridor,
      admin_rate: money_to_decimal(admin_rate),
      admin_total: money_to_decimal(admin_total),
      fixed_cost_percent: fixed_cost_percent,
      surplus_pay_option: surplus_pay_option,
      surplus_pay_month: surplus_pay_month
    }.compact

    hash.empty? ? nil : hash
  end

  # Build enrollment counts hash (only if present)
  def build_enrollment_hash(eo: nil, es: nil, ec: nil, ef: nil)
    counts = { eo: eo&.to_i, es: es&.to_i, ec: ec&.to_i, ef: ef&.to_i }.compact
    return nil if counts.empty?

    counts[:total] = counts.values.sum
    counts
  end
end
```

### Phase 3: Refactor Aetna Parser (Example Implementation)

**File**: `aetna/parsers/aetna_parse_pdf_job.rb`

```ruby
class AetnaParsePdfJob
  include Sidekiq::Worker
  include ActionView::Helpers::NumberHelper
  include ParserTestable
  include ParserUtilities

  sidekiq_options queue: :default, retry: 0

  CARRIER_ID = 71
  CARRIER_NAME = "Aetna"

  def perform(*args)
    doc_id = args[0]
    options = args[1].is_a?(Hash) ? args[1].symbolize_keys : {}

    # Route to test mode if requested
    if options[:test_mode] || options[:manual]
      return handle_test_mode(options)
    end

    # Normal database-connected mode
    process_document(doc_id)
  end

  # ─────────────────────────────────────────────────────────────
  # ParserTestable required methods
  # ─────────────────────────────────────────────────────────────

  def parse_file_content(file_path)
    pages = Iguvium.read(file_path)
    proposal_details = extract_quote_details(pages)
    parsed_data = parse_all_offers_data_from_pages(pages)

    {
      proposal_details: proposal_details,
      offers: parsed_data[:offers],
      renewal_offers: parsed_data[:renewal_offers]
    }
  end

  def format_test_output(raw_data)
    proposal = raw_data[:proposal_details] || {}

    {
      document_details: {
        effective_date: proposal[:effective_date],
        proposal_type: proposal[:proposal_type],
        city: proposal[:city],
        state: proposal[:state],
        zip: proposal[:zip],
        file_type: proposal[:proposal_type]&.include?("Level") ? "LF" : "FI",
        _carrier_specific: {
          isl_level: proposal[:isl_level],
          asl_level: proposal[:asl_level],
          stop_loss_max: proposal[:stop_loss_max],
          contract_type: proposal[:contract_type],
          surplus_return_type: proposal[:surplus_return_type],
          pepm: proposal[:pepm]
        }.compact
      },
      offers: raw_data[:offers].map { |o| format_offer(o, proposal) },
      renewal_offers: {
        current: raw_data[:renewal_offers][:current].map { |o| format_offer(o, proposal) },
        renewal: raw_data[:renewal_offers][:renewal].map { |o| format_offer(o, proposal) }
      },
      tags: determine_tags(proposal)
    }
  end

  private

  def format_offer(offer_data, proposal_details)
    result = {
      rate_plan_mapping: offer_data[:rate_plan_mapping],
      rates: build_rates_hash(
        eo: offer_data[:eo],
        es: offer_data[:es],
        ec: offer_data[:ec],
        ef: offer_data[:ef],
        total: offer_data[:total]
      )
    }

    # Add level-funded data if present
    if offer_data[:stop_loss] || offer_data[:agg]
      result[:level_funded] = build_level_funded_hash(
        isl_ded: proposal_details[:isl_level],
        isl_coverage: "medical + rx",
        asl_corridor: parse_asl_corridor(proposal_details[:asl_level]),
        admin_rate: offer_data[:admin],
        fixed_cost_percent: calculate_fixed_cost_percent(offer_data),
        surplus_pay_option: "#{proposal_details[:surplus_return_type]} Admin Credit",
        surplus_pay_month: "16th month"
      )
    end

    # Add enrollment if present
    if offer_data[:eo_enrolled]
      result[:enrollment_counts] = build_enrollment_hash(
        eo: offer_data[:eo_enrolled],
        es: offer_data[:es_enrolled],
        ec: offer_data[:ec_enrolled],
        ef: offer_data[:ef_enrolled]
      )
    end

    result
  end

  # ... rest of existing methods unchanged ...
end
```

### Phase 4: Create Migration Guide for Other Parsers

To add test mode to any existing parser:

1. **Add includes**:
   ```ruby
   include ParserTestable
   include ParserUtilities
   ```

2. **Modify `perform` method**:
   ```ruby
   def perform(*args)
     doc_id = args[0]
     options = args[1].is_a?(Hash) ? args[1].symbolize_keys : {}

     return handle_test_mode(options) if options[:test_mode]

     # ... existing code ...
   end
   ```

3. **Implement `parse_file_content`**:
   - Extract the file-loading and parsing logic
   - Return raw parsed data hash

4. **Implement `format_test_output`**:
   - Map raw data to standardized schema
   - Use helper methods from `ParserUtilities`

---

## Usage Examples

### Single File Testing

```ruby
# Via class method
AetnaParsePdfJob.test_file("/path/to/proposal.pdf")

# Via perform with options
AetnaParsePdfJob.new.perform(nil, {
  test_mode: true,
  file_path: "/path/to/proposal.pdf"
})
```

### Directory Batch Testing

```ruby
# Test all PDFs in a directory
AetnaParsePdfJob.test_directory("/path/to/test_files/")

# Test with custom pattern
UnitedRenewalParserJob.test_directory("/path/to/files/", pattern: "**/renewal_*.pdf")
```

### Rails Console Usage

```ruby
# Quick test with output to console
result = BcbsParsePdfJob.test_file("~/Downloads/bcbs_quote.pdf")
puts result[:files].first[:offers].map { |o| o[:rate_plan_mapping] }

# Compare parsing across multiple files
results = UnitedRenewalParserJob.test_directory("~/test_pdfs/united/")
results[:files].each do |f|
  puts "#{f[:file]}: #{f[:success] ? f[:offers].count : f[:error]}"
end
```

### Custom Output Location

```ruby
AetnaParsePdfJob.new.perform(nil, {
  test_mode: true,
  directory_path: "/input/files/",
  output_path: "/results/output/"
})
```

---

## File Organization

```
lib/
├── concerns/
│   ├── parser_testable.rb      # Core testing framework
│   └── parser_utilities.rb     # Shared parsing helpers
│
aetna/
├── parsers/
│   └── aetna_parse_pdf_job.rb  # Updated with ParserTestable
│
united/
├── parsers/
│   ├── united_renewal_parser_job.rb      # Updated
│   ├── united_renewal_parse_pdf_job.rb   # Updated
│   └── ...
│
bcbs/
├── parsers/
│   └── bcbs_parse_pdf_job.rb   # Updated
│
test/
├── parser_test_files/          # Sample files for testing
│   ├── aetna/
│   ├── united/
│   └── bcbs/
└── parser_results/             # Default output location
```

---

## Rollout Strategy

### Week 1: Foundation
- [ ] Create `lib/concerns/parser_testable.rb`
- [ ] Create `lib/concerns/parser_utilities.rb`
- [ ] Refactor `AetnaParsePdfJob` as reference implementation
- [ ] Test with existing Aetna sample files

### Week 2: United Parsers
- [ ] Update `UnitedRenewalParserJob`
- [ ] Update `UnitedRenewalParsePdfJob`
- [ ] Update `UnitedBackfillTotalEnrolledJob`
- [ ] Consolidate duplicate code in United parsers

### Week 3: BCBS & Other Carriers
- [ ] Update `BcbsParsePdfJob`
- [ ] Update remaining BCBS parsers
- [ ] Update Humana, All Savers, and other parsers

### Week 4: Documentation & Testing
- [ ] Create comprehensive test file collection
- [ ] Document expected output for each parser
- [ ] Create comparison scripts for regression testing

---

## Benefits

1. **DRY Principle**: Testing infrastructure defined once, used everywhere
2. **Consistent Output**: All parsers produce identically-structured JSON
3. **Easy Debugging**: Run parsers locally without database setup
4. **Regression Testing**: Compare outputs across code changes
5. **Onboarding**: New developers can test parsers immediately
6. **QA Support**: QA team can validate parsing without Rails console expertise

---

## Future Enhancements

1. **Web UI**: Simple interface to upload files and view parsed results
2. **Diff Tool**: Compare two JSON outputs to highlight changes
3. **Validation Rules**: Define expected fields per carrier for auto-validation
4. **CI Integration**: Run parser tests against sample files on PR
5. **Performance Metrics**: Track parsing speed regressions
