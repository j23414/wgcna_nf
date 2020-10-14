#! /usr/bin/env nextflow

nextflow.enable.dsl=2

def helpMsg() {
  log.info """
   Usage:
   The typical command for running the pipeline is as follows:
   nextflow run main.nf --xlsx RNASeq.xlsx
   nextflow run main.nf --file RNASeq.csv --delim ','

   Mandatory arguments:
    --xlsx                  Excel file containing RNASeq counts where [columns = treatment; rows = genes/gene-probes]
    or
    --file                  Text file containing RNASeq counts where [columns = treatment; rows = genes/gene-probes]
    --delim                 Specifies the delimiter of the textfile [default: '\t']

   Optional configuration arguments:
    -profile                Configuration profile to use. Can use multiple (comma separated)
                            Available: local, condo, atlas, singularity [default:local]

   Optional other arguments:
    --help
"""
}

if (params.help) {
  helpMsg()
  exit 0
}

if( !params.xlsx & !params.file) {
  helpMsg()
  exit 0
}


process read_xlsx {
  tag "$xlsx.fileName"

  input:
  path xlsx

  output:
  path "${xlsx.simpleName}.RData"

  script:
  """
  #! /usr/bin/env Rscript
  data <- readxl::read_excel("$xlsx")
  names(data) <- gsub(":","_", names(data))
  save(data, file="${xlsx.simpleName}.RData")
  """
}

process read_delim {
  tag "$infile.fileName"

  input:
  path infile

  output:
  path "${infile.simpleName}.RData"

  script:
  """
  #! /usr/bin/env Rscript
  data <- readr::read_delim("$infile", delim="$params.delim")
  names(data) <- gsub(":","_", names(data))
  save(data, file="${infile.simpleName}.RData")
  """
}

workflow {
  println("Hello world")

  if ( params.xlsx ) {
    rnaseq_ch = channel.fromPath(params.xlsx, checkIfExists:true) |
      read_xlsx |
      view
  } else {
    rnaseq_ch = channel.fromPath(params.file, checkIfExists:true) |
      read_delim |
      view
  }
}
