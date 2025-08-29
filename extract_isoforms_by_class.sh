#!/bin/bash

INPUT_FILE="P29702_301.transcriptome_copy.gff.gz"

# Get unique class codes
CLASS_CODES=$(zcat "$INPUT_FILE" | awk -F'\t' '$3=="transcript" && $9 ~ /class_code/ {
    match($9, /class_code "([^"]+)"/, arr)
    if (arr[1] != "") print arr[1]
}' | sort | uniq)

for CODE in $CLASS_CODES; do
    echo "Processing class_code: $CODE"

    zcat "$INPUT_FILE" | awk -v code="$CODE" -F '\t' '
        $3=="transcript" && $9 ~ ("class_code \"" code "\"") {
            split($9, a, ";")
            for (i in a) {
                gsub(/^ +| +$/, "", a[i])
                if (a[i] ~ /^transcript_id/) t_id = gensub(/.*"([^"]+)".*/, "\\1", "g", a[i])
                if (a[i] ~ /^gene_id/) g_id = gensub(/.*"([^"]+)".*/, "\\1", "g", a[i])
                if (a[i] ~ /^xloc/) xloc = gensub(/.*"([^"]+)".*/, "\\1", "g", a[i])
            }
            len = $5 - $4 + 1
            # Add 'code' as the last column to output
            print $1, $4, $5, $7, len, t_id, g_id, xloc, code
        }
    ' OFS="\t" > isoforms_class_${CODE}.tsv
done

echo "Done. Extracted isoforms saved as .tsv files per class code."

