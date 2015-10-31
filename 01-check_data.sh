#!/bin/bash

set -e
source config
exec &> >(tee ${check_data_logfile})

Rscript resources/datacheck/datacheck.R \
	${bfile_raw}.bim \
	${bfile_raw}.fam \
	${betas} \
	${covariates} \
	${provided_cellcounts} \
	${intersect_ids} \
	${intersect_ids_plink} \
	${snpcheck} \
	${snpplot} \
	${control_snps} \
	${phenotypes} \
	${cnvs} \
	${cohort_descriptives} \
	${ageplot} \
	${ewas_results}.phenotype_list

