#!/bin/bash

# Job Flags
#SBATCH -p mit_normal -c 4 -t 06:00:00 --mem-per-cpu 4000

module load miniforge
source activate secrify
set -euo pipefail
sample="$1"
raw_dir="./raw"
trim_dir="./trimmed"
align_dir="./alignments"

mkdir -p "$raw_dir" "$trim_dir" "$align_dir"

trim_galore --illumina --stringency 10 --paired $raw_dir/${sample}_1.fastq.gz $raw_dir/${sample}_2.fastq.gz --output_dir "$trim_dir"
cutadapt -j 0 -g ATGACGATAAGGCCGAGATGGCC -g GGAGAGGGTTAGGGATAGGCTTACCATTAATTAA -G ATGACGATAAGGCCGAGATGGCC -G GGAGAGGGTTAGGGATAGGCTTACCATTAATTAA --minimum-length 20 -O 10 --discard-untrimmed \
    -o "$trim_dir"/${sample}_1_trim.fastq.gz -p "$trim_dir"/${sample}_2_trim.fastq.gz "$trim_dir"/${sample}_1_val_1.fq.gz "$trim_dir"/${sample}_2_val_2.fq.gz 

bash "$HOME/software/BBTools-indexfix/bbmap.sh" \
    -Xmx12g threads=4 \
    path="/orcd/scratch/orcd/008/imjeffli/secrify/bbmap_index_fixed" \
    maxindel=300 xstag=us intronlen=10 ambig=best \
    in="$trim_dir/${sample}_1_trim.fastq.gz" \
    in2="$trim_dir/${sample}_2_trim.fastq.gz" \
    out="$align_dir/${sample}_txmapped.sam"
    
samtools view -bS "$align_dir"/${sample}_txmapped.sam > "$align_dir"/${sample}_txmapped.bam  
samtools flagstat "$align_dir"/${sample}_txmapped.bam

samtools view -b -f2 "$align_dir"/${sample}_txmapped.bam > "$align_dir"/${sample}_pp_txmapped.bam 

samtools flagstat "$align_dir"/${sample}_pp_txmapped.bam 
samtools sort -o "$align_dir"/${sample}_pp_txmapped_sort.bam "$align_dir"/${sample}_pp_txmapped.bam 
samtools flagstat "$align_dir"/${sample}_pp_txmapped_sort.bam 
samtools index "$align_dir"/${sample}_pp_txmapped_sort.bam 