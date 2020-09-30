################################	Differential Gene expression 	################################
# Kallisto (Bray et al., 2016)                                						               #
# DESeq2 (Love et al., 2014)       
# Sleuth (Pimentel et al., 2017)                       	 						               #
####################################################################################################

rule KallistoIndex:
	input:
		fasta=lambda wildcards:config['ref']['transcriptome']
	output:
		index="resources/reference/kallisto.idx"
	log:
		"logs/kallisto/index.log"
	wrapper:
		"0.65.0/kallisto/index"

rule KallistoQuant:
	input:
		fastq=expand("resources/reads/{{sample}}_{n}.fastq.gz", n=[1,2]),
		index="resources/reference/kallisto.idx"
	output:
		directory("results/quant/{sample}")
	params:
		bootstrap="-b 100"
	threads:12
	log:
		"logs/kallisto/quant_{sample}.log"
	shell:
		"0.65.0/bio/kallisto/quant"

rule DifferentialGeneExpression:
	input:
		expand("results/quant/{sample}", sample=samples),
		samples = config['samples']
	output:
		"results/diff/RNA-Seq_diff.xlsx",
		DEcomparisons="resources/DE.comparison.list",
	log:
		"logs/DESeq2/geneDE.log"
	script:
		"../scripts/kallistoDE.R"

rule DifferentialIsoformExpression:
	input:
		expand("results/quant/{sample}", sample=samples),
		samples = config['samples']
	output:
		"results/isoformdiff/RNA-Seq_isoformdiff.xlsx"
	log:
		"logs/sleuth/isoformDE.log"
	script:
	    "../scripts/sleuthIsoformsDE.R"