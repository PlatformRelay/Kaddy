# shellcheck shell=bash
# tests/deck/lib.sh — shared slide/note extraction for the E12 deck gates.
#
# Contract enforced on slides/slides.md (documented here, asserted by the
# tests that source this lib):
#   * Every slide starts with a `---` frontmatter block (Slidev separator
#     convention used throughout this deck) — the parser pairs `---` lines.
#   * The presenter note of a slide is the LAST `<!-- ... -->` HTML comment
#     block in that slide (Slidev's own presenter-note rule). Earlier comment
#     blocks (e.g. housekeeping notes) are ignored.
#   * Code fences (``` ... ```) are skipped entirely, so `---` or `<!--`
#     inside code samples never miscount slides or notes.
#
# extract_notes <slides.md> prints one line per slide:
#   <index> <cover|content> <note-word-count>
# where `cover` marks a <CoverArt> section-divider slide.

extract_notes() {
  awk '
    BEGIN { state = "pre"; fence = 0; slide = 0 }
    {
      line = $0
      if (state == "pre") {
        if (line == "---") state = "fm"
        next
      }
      if (state == "fm") {
        if (line == "---") { state = "content"; slide++ }
        next
      }
      # state == content
      if (!fence && line == "---") { state = "fm"; next }
      if (line ~ /^```/) { fence = !fence; next }
      if (fence) next
      content[slide] = content[slide] line "\n"
      if (line ~ /<CoverArt/) iscover[slide] = 1
    }
    END {
      for (i = 1; i <= slide; i++) {
        n = split(content[i], L, "\n")
        incmt = 0; cur = ""; last = ""
        for (j = 1; j <= n; j++) {
          l = L[j]
          if (!incmt && l ~ /^<!--/) {
            cur = l; sub(/^<!--/, "", cur)
            if (l ~ /-->/) { sub(/-->.*/, "", cur); last = cur; cur = "" }
            else incmt = 1
            continue
          }
          if (incmt) {
            if (l ~ /-->/) { t = l; sub(/-->.*/, "", t); cur = cur " " t; last = cur; incmt = 0; cur = "" }
            else cur = cur " " l
          }
        }
        c = 0
        n2 = split(last, W, /[ \t]+/)
        for (k = 1; k <= n2; k++) if (W[k] != "") c++
        printf "%d %s %d\n", i, (iscover[i] ? "cover" : "content"), c
      }
    }
  ' "$1"
}
