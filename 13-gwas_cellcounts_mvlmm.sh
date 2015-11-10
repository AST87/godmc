#!/bin/bash

set -e
source config

cd ${section_13_dir}

batch=${1}
re='^[0-9]+$'
if ! [[ $batch =~ $re ]] ; then
	echo "error: Batch variable is not a number"
	echo "Please provide a number between 1 and 'genetic_chunks'"
	echo "Usage: ${0} [batch]"
	exit 1
fi
exec &> >(tee ${section_13_logfile}${batch})

# Get SNP list
echo "Data is split into ${genetic_chunks} chunks"
echo "Running chunk ${batch}"

awk '{ print $1 }' ${tabfile}.tab.${batch} | sed 1d > ${bfile}.snplist.${batch}

echo "Formatting data for batch ${batch}"
plink1.90 \
	--bfile ${bfile} \
	--extract ${bfile}.snplist.${batch} \
	--make-bed \
	--out ${bfile}_${batch}

cut -d " " -f 1-5 ${bfile}_${batch}.fam | tr ' ' '\t' > ${bfile}_${batch}.fam.temp
paste -d "\t" ${bfile}_${batch}.fam.temp ${cellcounts_tf}.gemma > ${bfile}_${batch}.fam

nval=`awk '{ print NR }' ${section_13_dir}/cellcounts_columns.txt | tr '\n' ' '`
echo "Performing multivariate LMM on ${nval} cellcount phenotypes"

${gemma} \
	-bfile ${bfile}_${batch} \
	-k ${grmfile_all}.gemma \
	-n ${nval} \
	-lmm 4 \
	-o cellcounts_mvlmm_${batch}

echo "Compressing results"
gzip -f output/cellcounts_mvlmm_${batch}.assoc.txt
mv output/cellcounts_mvlmm_${batch}.* ${section_13_dir}

rm ${bfile}_${batch}*

echo "Successfully performed multivariate LMM on cellcounts for chromsome ${batch}"
