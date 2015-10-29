#!/bin/bash

set -e
source config
exec &> >(tee ${methylation_adjustment2_logfile})

batch_number=${1}

echo "Adjusting methylation for meth PCs"

if [ -n "${1}" ]
then
	re='^[0-9]+$'
	if ! [[ $batch_number =~ $re ]] ; then
		echo "error: Batch variable is not a number"
		exit 1
	fi
	i=${1}
	echo "Running batch ${i} of ${meth_chunks}"
else
	i="NA"
	echo "Running entire set on a single node using ${nthreads} threads."
fi


Rscript resources/methylation/adjust_covs.R \
	${methylation_adjusted}.RData \
	${nongenetic_meth_pcs}.txt \
	${methylation_adjusted_pcs} \
	${nthreads} \
	${meth_chunks} \
	${i}
