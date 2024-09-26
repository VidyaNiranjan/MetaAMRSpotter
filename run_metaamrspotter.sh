
#!/bin/bash

clear='\033[0m'
green='\033[0;32m'

# Specify the directory where your .gz files are located

# Unzip all .gz files in the directory
for file in *.gz; do
  # Check if the file exists and is a .gz file
  if [ -e "$file" ]; then
    echo "Unzipping $file..."
    gunzip "$file"
    echo "Done."
  else
    echo "File not found or not a .gz file: $file"
  fi
done

echo -e "${green}MetaAMRSpotter Pipeline${clear}"

echo "FastQC"

# Check if the "fastqc" directory exists, and create it if not
if [ ! -d "fastqc" ]; then
  mkdir fastqc
fi

# Create an array to store unique prefixes
prefixes=()

# Loop through all FASTQ and FASTQ.gz files in the current directory
for input_file in *.fastq; do
  # Extract the prefix from the input file name
  prefix=$(basename "$input_file" | sed -E 's/_[12]\.(fastq|fastq.gz)//')
  
  # Check if the prefix is already in the array
  if [[ ! " ${prefixes[@]} " =~ " $prefix " ]]; then
    prefixes+=("$prefix")
    
    # Find the input files for this prefix
    input_r1="${prefix}_1.fastq"
    input_r2="${prefix}_2.fastq"

    # Define output file names based on the prefix
    output_r1_paired="result/${prefix}/trimmomatic/1_paired.fastq"
    output_r2_paired="result/${prefix}/trimmomatic/2_paired.fastq"
    output_r1_unpaired="result/${prefix}/trimmomatic/1_unpaired.fastq"
    output_r2_unpaired="result/${prefix}/trimmomatic/2_unpaired.fastq"
    mkdir -p "result/${prefix}/fastqc"
    mkdir -p "result/${prefix}/trimmomatic"
    echo "Processing prefix: $prefix"
    
    # Run fastqc on the input files and save the results in the "fastqc" directory
    fastqc "$input_r1" -o "result/${prefix}/fastqc/" -t 16
    fastqc "$input_r2" -o "result/${prefix}/fastqc/" -t 16
    
    echo "FastQC analysis completed for $prefix."
    
    echo "Trimmomatic process for $prefix"
    
    # Define Trimmomatic command with desired parameters
    java -jar trimmomatic-0.39.jar PE -phred33 "$input_r1" "$input_r2" "$output_r1_paired" "$output_r1_unpaired" "$output_r2_paired" "$output_r2_unpaired" ILLUMINACLIP:TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36    
    # Check the exit status of the Trimmomatic command
    if [ $? -eq 0 ]; then
      echo "Trimmomatic completed successfully for $prefix."
    else
      echo "Trimmomatic encountered an error for $prefix."
    fi
  
    echo "bowtie2 alignment"

    # Define the index file
    index="/reference/indexed_file"

    output_dir="result/${prefix}/mapping"
    mkdir -p "$output_dir"
    input_file_1="result/${prefix}/trimmomatic/1_paired.fastq"
    input_file_2="result/${prefix}/trimmomatic/2_paired.fastq"

  # Check if input files were found
    if [ -z "$input_file_1" ] || [ -z "$input_file_2" ]; then
        echo "Input files not found in the current directory."
        exit 1
    fi

  # Run bowtie2
    bowtie2 -x "$index" -1 "$input_file_1" -2 "$input_file_2" --un-conc "$output_dir/unmapped.fastq"


# Check the exit status of bowtie2
    if [ $? -eq 0 ]; then
        echo "bowtie2 alignment completed successfully."
    else
        echo "bowtie2 encountered an error."
    fi
    echo "SPAdes assembly with error correction"
    

    forward="result/${prefix}/mapping/unmapped.1.fastq"
    reverse="result/${prefix}/mapping/unmapped.2.fastq"
    output_path="result/${prefix}/assembly/spades/"
  
  # Run SPAdes
    spades.py --meta --pe1-1 "$forward" --pe1-2 "$reverse" -o "$output_path" --phred-offset  33 -t 64 -m 128 --only-error-correction
  
  # Rename and compress output files
    output_dir="$output_path/corrected"
    output_file_1="$output_dir/unmapped.100.0_0.cor.fastq.gz"
    output_file_2="$output_dir/unmapped.200.0_0.cor.fastq.gz"
    
    echo "SPAdes assembly with error correction done"
    echo "SPAdes assembly"
    forward="result/${prefix}/assembly/spades/corrected/unmapped.100.0_0.cor.fastq.gz"
    reverse="result/${prefix}/assembly/spades/corrected/unmapped.200.0_0.cor.fastq.gz"
    output_path="result/${prefix}/assembly/spades/contigs"
  
  # Run SPAdes
    spades.py --meta --pe1-1 "$forward" --pe1-2 "$reverse" -o "$output_path" -t 64 -m 128 --only-assembler
  
  # Rename and compress output files
    output_dir="$output_path/corrected/contigs"
    output_file="$output_dir/contigs.fasta"
    
    echo "SPAdes assembly is done"
    echo "QUAST"
    input="result/${prefix}/assembly/spades/contigs/contigs.fasta"
    output_path="result/${prefix}/quast"
  
    # Run quast
    quast.py "$input" -o "$output_path" --min-contig 100
    
    echo "QUAST is done"
    echo "Metaphlan"
    output_dir="result/${prefix}/metaphlan"
    mkdir -p "$output_dir"
    output_file_2="result/${prefix}/metaphlan/metagenome.bowtie2.bz2"
    output_file_1="result/${prefix}/metaphlan/profiled.txt"
    
    input_r1_pattern="result/${prefix}/trimmomatic/1_paired.fastq"
    input_r2_pattern="result/${prefix}/trimmomatic/2_paired.fastq"

  # Check if input files were found

    metaphlan "$input_r1_pattern","$input_r2_pattern" --bowtie2out "$output_file_2" --nproc 32 --input_type fastq -o "$output_file_1"
    echo "Metaphlan is done"
    
    echo "abricate"
    
    input="result/${prefix}/assembly/spades/contigs/contigs.fasta"
    output_dir="result/${prefix}/abricate"
    mkdir -p "$output_dir"
    output_amr="result/${prefix}/abricate/amr.txt"
    output_pf="result/${prefix}/abricate/pf.txt"
    output_vf="result/${prefix}/abricate/vf.txt"
    log_amr="result/${prefix}/abricate/amr.log"
    log_pf="result/${prefix}/abricate/pf.log"
    log_vf="result/${prefix}/abricate/vf.log"


    echo "Abricate AMR"
    abricate --threads 32 --mincov 60 --db ncbi "$input" > "$output_amr" 2> "$log_amr"

    echo "Abricate Plasmidfinder"
    abricate --threads 32 --mincov 60 --db plasmidfinder "$input" > "$output_pf" 2> "$log_pf"

    echo "Abricate Virulencefactor"
    abricate --threads 32 --mincov 60 --db vfdb "$input" > "$output_vf" 2> "$log_vf"
    
    echo "abricate is done"

    echo "abricate summary"
    input_amr="result/${prefix}/abricate/amr.txt"
    input_pf="result/${prefix}/abricate/pf.txt"
    input_vf="result/${prefix}/abricate/vf.txt"
    output_amr="result/${prefix}/abricate/amr_summary.txt"
    output_pf="result/${prefix}/abricate/pf_summary.txt"
    output_vf="result/${prefix}/abricate/vf_summary.txt"
   

    echo "Abricate AMR Summary"
    abricate --summary "$input_amr" > "$output_amr" 

    echo "Abricate Plasmidfinder Summary"
    abricate --summary "$input_pf" > "$output_pf" 

    echo "Abricate Virulencefactor Summary"
    abricate --summary "$input_vf" > "$output_vf" 
    
    echo "abricate summary is done"
  fi
done

