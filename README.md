# MetaAMRSpotter
MetaAMRSpotter is an open-source pipeline for detecting antimicrobial resistance (AMR) genes from metagenomic data. It automates quality control, taxonomic classification, and AMR gene identification with a single command. Ideal for use in clinical diagnostics, environmental monitoring, and food safety research.

**Disclaimer**
This protocol can be run on Linux & Ubuntu systems with enough RAM and memory (for databases and tools) to enable appropriate data run and generation.

**Key Features:**
Comprehensive metagenomic analysis pipeline.
Automated tools execution, reducing manual setup.
Compatible with both Linux desktop systems and high-performance computing clusters.
Suitable for various metagenomic sample types.

**Tools and Installation**
Below are the tools required for MetaAMRSpotter. Each tool includes installation links and basic usage instructions.
1. FastQC: Quality Control for Sequence Data
Function: Checks quality of raw reads.
Installation: sudo apt-get install fastqc
Source: FastQC Website - https://www.bioinformatics.babraham.ac.uk/projects/download.html#fastqc
2. Trimmomatic: Adapter Removal and Quality Trimming
Function: Trims low-quality sections and removes adapters from sequencing data.
Installation:sudo apt-get install trimmomatic
Source: Trimmomatic - https://github.com/timflutre/trimmomatic
3. Bowtie2: Sequence Alignment
Function: Aligns sequences against a reference genome.
Installation:sudo apt-get install bowtie2
Source: Bowtie2 - https://github.com/BenLangmead/bowtie2
4. SPAdes: Genome Assembly Tool
Function: Assembles genome using de Bruijn graphs.
Installation:sudo apt-get install spades
Source: SPAdes GitHub - https://github.com/ablab/spades
5. Quast: Genome Assembly Quality Assessment
Function: Evaluates the quality of assembled genomes.
Installation:sudo apt-get install quast
Source: Quast GitHub - https://github.com/ablab/quast, https://quast.sourceforge.net/metaquast
6. MetaPhlAn: Taxonomic Classification of Microbial Communities
Function: Profiles microbial communities from metagenomic data.
Installation:pip install metaphlan
Source: MetaPhlAn - https://github.com/biobakery/MetaPhlAn
7. Abricate: AMR Gene Prediction
Function: Identifies antimicrobial resistance genes.
Installation:sudo apt-get install abricate
Source: Abricate GitHub - https://github.com/tseemann/abricate

**Databases**
Two databases need to be installed to run the MetaPhlAn and Abricate tools:
1. MetaPhlAn Database
Command:metaphlan --install
2. Abricate Database (AMR, Virulence factor, Plasmid Finder)
Command:abricate --setupdb

**Database Setup**
Ensure MetaPhlAn and Abricate databases are properly installed as described in the Databases section.
Reference Genome Indexing (Required for Bowtie2) Index the reference genome for alignment using Bowtie2.
Code: bowtie2-build <reference.fasta> <index_name>

**Usage Instructions**
Prepare Input Data Place the raw sequence data in a directory. The pipeline supports paired-end FASTQ files.
Run MetaAMRSpotter Use the shell script to run the complete pipeline. Replace <input_dir> with your input directory:
Code: bash run_metaamrspotter.sh <input_dir>

**Output**
The pipeline generates several outputs, including:
Quality control reports from FastQC.
Trimmed reads.
Aligned sequences (Bowtie2).
Assembled genome (SPAdes).
Microbial community profiles (MetaPhlAn).
AMR gene predictions (Abricate).

**Published Protocol Paper**
Chandrashekar, K., Setlur, A. S., Pooja, S., Rao, M. P., & Niranjan, V. (2024). MetaAMRSpotter: Automated workflow with shell scripting for uncovering hidden AMR hotspots from metagenomes. https://dx.doi.org/10.17504/protocols.io.e6nvw1jyzlmk/v1
