#!/bin/bash

set -e

echo "Updating system and installing core dependencies..."
sudo apt-get update
sudo apt-get install -y wget unzip bzip2 build-essential openjdk-11-jre

echo "Creating conda environment 'metaamrspotter'..."
conda create -y -n metaamrspotter python=3.10
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate metaamrspotter

echo "Installing bioinformatics tools via conda..."
conda install -y -c bioconda fastqc trimmomatic bowtie2 spades quast metaphlan abricate

echo "Downloading Trimmomatic adapters..."
wget -nc https://github.com/timflutre/trimmomatic/raw/master/adapters/TruSeq3-PE.fa

echo "Setting up reference index for Bowtie2..."
# Replace '/reference/indexed_file' with your actual reference file path
mkdir -p reference
if [ ! -f reference/reference.fasta ]; then
    echo "Please provide your reference genome as 'reference/reference.fasta'"
    # Optionally, download a public reference here
fi
if [ -f reference/reference.fasta ]; then
    bowtie2-build reference/reference.fasta reference/indexed_file
fi

echo "Downloading MetaPhlAn database..."
metaphlan --install --nproc 8

echo "Configuring Abricate and downloading databases..."
abricate --setupdb

echo "Installation and setup complete!"
