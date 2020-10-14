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
    --delim                 Specifies the delimiter of the textfile [default: '\\t']

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

process fetch_testdata {
  publishDir './'

  output:
  path "*"

  script:
  """
  #! /usr/bin/env bash
  wget https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/Tutorials/FemaleLiver-Data.zip
  unzip FemaleLiver-Data.zip
  """
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

process plot_expression {
  input:
  path in_RData
  // specify expression columns
  // specify gene probe column

  output:
  path "*"

  script:
  """
  #! /usr/bin/env Rscript
  library(magrittr)
  library(ggplot2)

  load(\"$in_RData\")
  cdata <- data %>%
    tidyr::pivot_longer(., cols = starts_with("F2"))

  p <- cdata %>% ggplot(., aes(x=name, y= value, group=substanceBXH)) +
    geom_line(alpha=0.5) +
    theme_bw() +
    theme(
      axis.text.x = element_text(angle=90, hjust=0.5)
      )+
    labs(
      x="treatment",
      y="expression"
      )
  ggsave("expression.png", plot=p, height=3, width=9)
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
      plot_expression |
      view
  }
}
