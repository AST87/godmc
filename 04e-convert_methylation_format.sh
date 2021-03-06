#!/bin/bash

set -e
source ./config
exec &> >(tee ${section_04e_logfile})
print_version


Rscript resources/methylation/methylation_matrixeqtl_format.R \
	${methylation_adjusted} \
	${methylation_adjusted_pcs} \
	${methylation_adjusted_pcs_sq} \
	${covariates_combined}.txt

echo "Successfully converted methylation data"
