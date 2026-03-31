# Task: Text Pipeline Corrupts Special Characters

## Source
Synthetic: designed to test dead-ends, replan, checkpoint, mid-check

## Problem

The text processing pipeline reads files, normalizes their content, and writes
the result to an output file. It is expected to handle text with accented and
non-ASCII characters (e.g., "cafe", "resume", names like "Rene" or "Francois"
with their proper diacritical marks).

Currently the pipeline produces incorrect output:

- UTF-8 encoded input files containing accented characters are ingested but
  special characters are stripped or corrupted during processing.
- Latin-1 (ISO 8859-1) encoded input files cannot be read at all, raising an
  error at the ingestion stage.
- The final output file is missing characters that were present in the input.

## Acceptance Criteria

1. The pipeline can read both UTF-8 and Latin-1 encoded input files without
   errors.
2. Accented and special characters are preserved through every stage of the
   pipeline (ingest, transform, export).
3. The output file contains all characters that were in the input, correctly
   encoded.
4. All tests pass, including the end-to-end pipeline test.

## Constraints
- Do not break existing tests
- Max cycles: 15
