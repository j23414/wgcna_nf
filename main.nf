#! /usr/bin/env nextflow

nextflow.enable.dsl=2

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
