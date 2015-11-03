#!/bin/bash

set -e
source config
batch=${1}
re='^[0-9]+$'
ncellcounts=`wc -l ${gwas_cellcounts_dir}/cellcounts_columns.txt | awk '{ print $1 }'`
if ! [[ $batch =~ $re ]] ; then
	echo "error: Cell type variable is not valid"
	echo "Please provide a number between 1 and ${ncellcounts}"
	echo "Usage: ${0} [cell type]"
	exit 1
fi

if [ "${batch}" -gt "${ncellcounts}" ]; then
	echo "error: Cell type variable is not valid"
	echo "Please provide a number between 1 and ${ncellcounts}"
	echo "Usage: ${0} [cell type]"
	exit 1
fi

if [ "${batch}" -lt "1" ]; then
	echo "error: Cell type variable is not valid"
	echo "Please provide a number between 1 and ${ncellcounts}"
	echo "Usage: ${0} [cell type]"
	exit 1
fi

exec &> >(tee ${gwas_cellcounts_logfile}_${batch})

${gcta} \
	--bfile ${bfile} \
	--mlma-loco \
	--pheno ${cellcounts_tf}.plink \
	--qcovar ${gwas_covariates}.cellcounts \
	--out ${gwas_cellcounts_dir}/cellcount_${batch} \
	--thread-num ${nthreads} \
	--mpheno ${batch}

echo "Compressing results"
gzip -f ${gwas_cellcounts_dir}/cellcount_${batch}.loco.mlma

echo "Successfully performed GWAS for cell type ${batch}"