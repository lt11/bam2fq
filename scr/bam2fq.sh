#!/bin/bash

## header  --------------------------------------------------------------------

### the one that converts a bam file, e.g. downloaded from dbgap, to fq files

## settings  ------------------------------------------------------------------

dir_full=$(cd $(dirname "${0}") && pwd)
dir_base=$(dirname "${dir_full}")
pll_runs=10
n_char=8
### input folder with all the files to be converted
dir_bam="${dir_base}/bam"
### output folders
dir_log="${dir_base}/log"
dir_fq="${dir_base}/fq"
if [[ ! -d "${dir_log}" ]]; then mkdir "${dir_log}"; fi
if [[ ! -d "${dir_fq}" ]]; then mkdir "${dir_fq}"; fi

## clmnt  ---------------------------------------------------------------------

all_bams=$(find "${dir_bam}" -name "*realn.bam")

pll_check=$((pll_runs + 1))
for one_bam in ${all_bams}; do
  ### parallel samples
  ((cnt_p++))
  if (( cnt_p % pll_check == 0 )); then
    wait -n
    cnt_p=$(( pll_check - 1 ))
  fi

  (
  random_string=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "${n_char}")
  new_id=$(basename $(echo "${one_bam}") | \
  sed 's|_wxs_gdc_realn.bam||' | sed 's|-||g')
  echo "${new_id}"
  echo "${one_bam}"
  samtools fastq \
  --threads 4 \
  -1 "${dir_fq}/${new_id}-R1.fq" \
  -2 "${dir_fq}/${new_id}-R2.fq" \
  "${one_bam}" 2> "${dir_log}/${new_id}.txt"
  rm -f "${one_bam}"
  fastq_pair "${dir_fq}/${new_id}-R1.fq" "${dir_fq}/${new_id}-R2.fq"
  rm -f "${dir_fq}/${new_id}-R1.fq.single.fq"
  rm -f "${dir_fq}/${new_id}-R2.fq.single.fq"
  rm -f "${dir_fq}/${new_id}-R1.fq"
  rm -f "${dir_fq}/${new_id}-R2.fq"
  mv "${dir_fq}/${new_id}-R1.fq.paired.fq" "${dir_fq}/${new_id}-R1.fq"
  mv "${dir_fq}/${new_id}-R2.fq.paired.fq" "${dir_fq}/${new_id}-R2.fq"
  gzip "${dir_fq}/${new_id}-R1.fq"
  gzip "${dir_fq}/${new_id}-R2.fq"
  ) > "${dir_log}/${random_string}.out" 2> "${dir_log}/${random_string}.err" &
done

wait
