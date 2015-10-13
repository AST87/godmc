library(MatrixEQTL)
library(parallel)

main <- function()
{
	arguments <- commandArgs(T)
	geno_root <- arguments[1]
	phen_file <- arguments[2]
	out_file <- arguments[3]
	threshold <- as.numeric(arguments[4])
	mc.cores <- as.numeric(arguments[5])


	slicesize <- 1000

	gene <- SlicedData$new()
	gene$fileDelimiter = "\t"
	gene$fileOmitCharacters = "NA"
	gene$fileSkipRows = 1
	gene$fileSkipColumns = 1
	gene$fileSliceSize = slicesize
	gene$LoadFile( paste0(phen_file, ".txt") )

	bn <- basename(geno_root)
	dn <- dirname(geno_root)
	geno_file <- list.files(dn, pattern=paste0("^", bn))

	l <- run_all_chunks(dn, geno_file, gene, threshold, slicesize, mc.cores)

	l1 <- unique(unlist(l))
	load(paste0(phen_file, ".RData"))
	pc <- pc[,!colnames(pc) %in% l1]
	message("Keeping ", ncol(pc), " non-genetic PCs.")
	pc <- data.frame(IID=rownames(pc), pc)
	write.table(pc, file=paste0(out_file, ".txt"), row=F, col=T, qu=F)
}

run_all_chunks_serial <- function(dn, geno_file, gene, threshold, slicesize)
{
	l <- list()
	for(i in 1:length(geno_file))
	{
		message(i, " of ", length(geno_file))
		snps = SlicedData$new()
		snps$fileDelimiter = "\t"
		snps$fileOmitCharacters = "NA"
		snps$fileSkipRows = 1
		snps$fileSkipColumns = 1
		snps$fileSliceSize = slicesize
		snps$LoadFile( file.path(dn, geno_file[i]) )
		l[[i]] <- run_chunk(snps, gene, threshold, slicesize)
	}
	return(l)
}

run_all_chunks <- function(dn, geno_file, gene, threshold, slicesize, mc.cores)
{
	tmpList = lapply(1:mc.cores, function(i){ seq(from=i, to=length(geno_file), by=mc.cores) })

	snps <- list()

	message("Performing GWAS on ", nrow(gene), " methylation PCs using ", mc.cores, " threads.")
	snps <- list()
	tmpAdj = mclapply(tmpList, function(ix)
	{
		l <- list()
		for(i in ix)
		{
			snps[[ix[1]]] = SlicedData$new()
			snps[[ix[1]]]$fileDelimiter = "\t"
			snps[[ix[1]]]$fileOmitCharacters = "NA"
			snps[[ix[1]]]$fileSkipRows = 1
			snps[[ix[1]]]$fileSkipColumns = 1
			snps[[ix[1]]]$fileSliceSize = slicesize
			snps[[ix[1]]]$LoadFile( file.path(dn, geno_file[i]) )
			l[[i]] <- run_chunk(snps[[ix[1]]], gene, threshold, slicesize)
		}
		return(l)
	}, mc.cores=mc.cores)
}


run_chunk <- function(snps, gene, threshold, slicesize)
{

	useModel = modelLINEAR
	errorCovariance = numeric()

	ids <- Reduce(intersect, list(snps$columnNames, gene$columnNames))

	snps$ColumnSubsample(match(ids, snps$columnNames))
	gene$ColumnSubsample(match(ids, gene$columnNames))

	stopifnot(all(snps$columnNames==gene$columnNames))

	me <- Matrix_eQTL_engine(
		snps = snps,
		gene = gene,
		cvrt = SlicedData$new(),
		output_file_name = NULL,
		pvOutputThreshold = threshold,
		useModel = useModel, 
		errorCovariance = errorCovariance, 
		verbose = TRUE,
		pvalue.hist = FALSE,
		min.pv.by.genesnp = FALSE,
		noFDRsaveMemory = FALSE
	)

	return(as.character(unique(me$all$eqtls$gene)))
}


main()
