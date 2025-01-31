# NGI-ONT_scRNAseq-tech_note-2025

This repository container supplementary information for the tech note "mRNA isoform detection by long-read sequencing of 10x single cell cDNA libraries" published by NGI in 2025.

## Supplementary figures

* [Supplementary Figure S1](Supplementary%20Figure%20S1.docx)
* [Supplementary Figure S2](Supplementary%20Figure%20S2.docx")

## Supplementary tables

* [Supplementary Table S1](Supplementary%20Table%20S1.docx)
* [Supplementary Table S2](Supplementary%20Table%20S2.docx)

## Supplementary methods

* [Supplementary method FLT-seq](Supplementary%20method%20FLT-seq.docx)

## Plot source code

A few of the figures in the this tech note were generated in jupyter notebooks. 

| File | Description |
| -------------------------- | ----------------------------------------------------------------------- |
| [plots/isoforms_usage.ipynb](plots/isoforms_usage.ipynb) | Comparing isoform presences and levels across the samples |
| [plots/tso_dists.ipynb](plots/tso_dists.ipynb) | Average position of TSO sequences within reads |
| [plots/tsos_vs_alns.ipynb](plots/tsos_vs_alns.ipynb) | Comparing the number of TSO per read versus number of alignments to the genome |


## Command-line scripts

### wf-single-cell extra statistic

```
# Parses the output file in results/SAMPLE/SAMPLE.read_tags.tsv
# UMIs per barcode
cut -f 4,5 SAMPLE.read_tags.tsv | sort -u | cut -f 1 | uniq -c | grep -v "corrected_barcode" | awk '{print $2"\t"$1}' > umis_per_barcode.tsv
# Reads per barcode
cut -f 4 SAMPLE.read_tags.tsv | sort | uniq -c | grep -v "corrected_barcode" | awk '{print $2"\t"$1}' > reads_per_barcode.tsv
# Genes per barcode
cut -f 2,4 SAMPLE.read_tags.tsv | sort | uniq -c | grep -v "corrected_barcode" | awk '{print $3"\t"$1-1}' | ruby -ane 'BEGIN{a={}};a[$F[0]]=a.fetch($F[0],0)+$F[1].to_i;END{a.each {|k, v| puts "#{k}\t#{v}"}}' > genes_per_barcode.tsv

# Mean and median
cut -f 2 genes_per_barcode.tsv | datamash mean 1 median 1 
```

### TSO search
We use the TSO sequence as the reference.fasta file:
```
>TSO
CCCATGTACTCTGCGTTGATACCACTGCTT
```

Then we can map and filter the data:
```
# Perform minimap2 mapping to find all TSO alignments
minimap2 --cs -m8 -k 10 -w 5 -A 6 -B 1 -c -t 8 $ref $fastq > out.paf
# Filter alignment sUniq MapQ>=20
awk '{if ($12 >=20){print $0}}' out.paf | cut -f 1 | sort | uniq | wc -l
# Find unique alignments 
cat out.paf | cut -f 1 | sort | uniq | wc -l
# Find relative distance of TSO from edge of reads
awk '{rs=(($4+$3)/2)/$2; if(rs >=0.5){print 1-rs}else{print rs}}'  out.paf
# Distance of TSO to edge in bp
awk '{ms=(($4+$3)/2); rs=ms/$2; if(rs >=0.5){print $2-ms}else{print ms}}' out.paf
# Binning reads by number of TSO hits per read;
cut -f out.paf | sort | uniq -c | awk '{print $1}' | sort | uniq -c
```

# Running wf-single-cell

```
# We use the cellranger standard reference package
refdir=/path/to/refdata-gex-GRCh38-2020-A
OUTPUT=results
nextflow run /path/to/wf-single-cell-1.0.3 \
    -w ./work \
    -profile singularity \
    -c extra.conf \
    --fastq /data/P29702_301.fastq.gz \
    --kit_name 3prime \
    --kit_version v3 \
    --expected_cells 500 \
    --ref_genome_dir $refdir \
    --out_dir ${OUTPUT} \
    --plot_umaps \
    --merge_bam

# Copy some tsv files the pipeline hides away in "tmp"
cp work/tmp/*/*/*.tsv results/
```

extra.conf:
```
process {
    withLabel:singlecell {
        container = "$baseDir/container/wf-single-cell_sha8e7d91013029ea8721743bd087583e5205cdc1dc.sif"
    }
    withLabel:wf_common {
                container = "$baseDir/container/wf-common_sha1c5febff9f75143710826498b093d9769a5edbb9.sif"
        }
    shell = ['/bin/bash', '-euo', 'pipefail']

    executor = 'slurm'
    time = '48.h'
    cpus = 4
    clusterOptions ='-A ngi2016004 -p node -n 6'
}
```
