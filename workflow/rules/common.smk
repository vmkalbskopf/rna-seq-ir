################################          Common functions           ##################################

## If PBS is activated
if config["pbs"]["activate"]:
    windowedStats = ["fst", "pbs"]
else:
    windowedStats = ["fst"]


def getFASTQs(wildcards, rules=None):
    """
    Get FASTQ files from unit sheet.
    If there are more than one wildcard (aka, sample), only return one fastq file
    If the rule is HISAT2align, then return the fastqs with -1 and -2 flags
    """
    
    if config["fastq"]["auto"]:
        units = pd.read_csv(config["samples"], sep="\t")
        units = (
            units.assign(fq1=f"resources/reads/" + units["sampleID"] + "_1.fastq.gz")
            .assign(fq2=f"resources/reads/" + units["sampleID"] + "_2.fastq.gz")
            .set_index("sampleID")
        )
    else:
        assert os.path.isfile(
            config["fastq"]["table"]
        ), f"config['fastq']['table'] (the config/fastq.tsv file) does not seem to exist. Please create one, or use the 'auto' option and name the fastq files as specified in the config/README.md"
        units = pd.read_csv(config["fastq"]["table"], sep="\t", index_col="sampleID")

    if len(wildcards) > 1:
        u = units.loc[wildcards.sample, f"fq{wildcards.n}"]
        return u
    else:
        u = units.loc[wildcards.sample, ["fq1", "fq2"]].dropna()
        if rules == "HISAT2align":
            return [f"-1 {u.fq1} -2 {u.fq2}"]
        else:
            return [f"{u.fq1}", f"{u.fq2}"]


def GetDesiredOutputs(wildcards):

    """
    Function that returns a list of the desired outputs for the rule all, depending on the config.yaml
    configuration file. As of V0.4.0 Does not list every single output, but should mean all rules and desired outputs are created.
    """

    wanted_input = []

    # QC & Coverage
    if config["qc"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/.input.check",
                    "resources/reads/qc/{sample}_{n}_fastqc.html",
                    "results/multiQC.html",
                ],
                sample=samples,
                n=[1, 2],
                chrom=config["chroms"],
            )
        )
        if config["VariantCalling"]["activate"]:
            wanted_input.extend(
            expand(
                [
                    "results/alignments/coverage/{sample}.mosdepth.summary.txt",
                    "results/alignments/bamStats/{sample}.flagstat",
                ],
                sample=samples,
            )
        )   

    # Differential Expression outputs
    wanted_input.extend(
        expand(
            [
                "results/genediff/{comp}.csv",
                "results/genediff/{dataset}_diffexp.xlsx",
                "results/isoformdiff/{comp}.csv",
                "results/isoformdiff/{dataset}_isoformdiffexp.xlsx",
                "results/plots/PCA.pdf",
                "results/quant/count_statistics.tsv",
            ],
            comp=config["contrasts"],
            dataset=config["dataset"],
        )
    )

    if config["progressiveGenes"]["activate"]:
        wanted_input.extend(
            expand(
                "results/genediff/{name}.{direction}.progressive.tsv",
                name=config["progressiveGenes"]["groups"],
                direction=["up", "down"],
            )
        )

    if config["VariantCalling"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/variants/vcfs/stats/{chrom}.txt",
                    "results/variants/plots/PCA-{chrom}-{dataset}.png",
                    "results/variants/plots/{dataset}_SNPdensity_{chrom}.png",
                    "results/variants/stats/SequenceDiversity.tsv",
                    "results/variants/fst.tsv",
                    "results/variants/TajimasD.tsv",
                    "results/variants/SequenceDiv.tsv",
                    "results/variants/plots/fst/{comp}.{chrom}.fst.{wsize}.png",
                ],
                chrom=config["chroms"],
                dataset=config["dataset"],
                comp=config["contrasts"],
                wsize=config["pbs"]["windownames"],
            )
        )


        if config['VariantCalling']['ploidy'] > 1:
            wanted_input.extend(
                expand(
                    [
                        "results/variants/stats/inbreedingCoef.tsv",
                    ]
                )
            )


    if config["AIMs"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/variants/AIMs/AIMs_summary.tsv",
                    "results/variants/AIMs/AIM_fraction_whole_genome.png",
                    "results/variants/AIMs/n_AIMS_per_chrom.tsv",
                    "results/variants/AIMs/AIM_fraction_{chrom}.tsv",
                ],
                chrom=config["chroms"],
            )
        )

    if config["IRmutations"]["activate"]:
        wanted_input.extend(["results/alleleBalance/alleleBalance.xlsx"])

    if config["GSEA"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/gsea/genediff/{comp}.DE.{pathway}.tsv",
                ],
                comp=config["contrasts"],
                pathway=["kegg", "GO"],
            )
        )

    if config["VariantCalling"]["activate"] and config["GSEA"]["activate"]:
        wanted_input.extend(
            expand(
                ["results/gsea/fst/{comp}.FST.{pathway}.tsv"],
                comp=config["contrasts"],
                pathway=["kegg", "GO"],
            )
        )

    if config["diffsnps"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/variants/diffsnps/{comp}.sig.kissDE.tsv",
                ],
                comp=config["contrasts"],
            )
        )

    if config["venn"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/RNA-Seq-full.xlsx",
                    "results/venn/{comp}_DE.Fst.venn.png",
                ],
                comp=config["contrasts"],
            )
        )

    if config["karyotype"]["activate"]:
        wanted_input.extend(
            expand(
                ["results/karyotype/{karyo}.karyo.txt"],
                karyo=config["karyotype"]["inversions"],
            )
        )

    if config["sweeps"]["activate"]:
        wanted_input.extend(
            expand(
                [
                    "results/genediff/ag1000gSweeps/{comp}_swept.tsv",
                ],
                comp=config["contrasts"],
            )
        )

    # wanted_input.extend(["results/quant/percentageContributionGeneCategories.tsv"])

    return wanted_input


def welcome(version):

    print("---------------------------- RNA-Seq-IR ----------------------------")
    print(f"Running RNA-Seq-IR snakemake workflow in {workflow.basedir}\n")
    print(f"Author:   Sanjay Curtis Nagi")
    print(f"Workflow Version: {version}")
    print("Execution time: ", datetime.datetime.now())
    print(f"Dataset: {config['dataset']}", "\n")
