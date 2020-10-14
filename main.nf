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
    --power                 Soft threshold power, will probably need to be adjusted [default:6]
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
  data <- readr::read_delim("$infile",
                            delim="$params.delim")
  names(data) <- gsub(":", "_", names(data))
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

process prep_data {
  tag "${in_RData.fileName}"
  input:
  path in_RData

  output:
  path "${in_RData.simpleName}_mat.RData"

  script:
  """
  #! /usr/bin/env Rscript
  load('$in_RData')
  library(magrittr)

  inputMatrix <- data %>%
    dplyr::select(starts_with("F2")) %>%
    {
      row.names(.) = data\$substanceBXH
      .
    } %>%
    t(.)

  save(inputMatrix, file = '${in_RData.simpleName}_mat.RData')

  """
}

process pick_soft_threshold {
  tag "${in_RData.fileName}"
  input:
  path in_RData

  output:
  path "*"

  script:
  """
  #! /usr/bin/env Rscript
  library(WGCNA)
  allowWGCNAThreads()

  load('$in_RData')

  powers = c(c(1:10), seq(from=12, to=20, by=2))
  sft = pickSoftThreshold(
    inputMatrix,
    powerVector = powers,
    verbose = 5
    )

  # Plot the results:
  png("softthreshold.png", width=800, height=400)
  par(mfrow = c(1,2));
  cex1 = 0.9;
  plot(
    sft\$fitIndices[, 1],
    -sign(sft\$fitIndices[, 3]) * sft\$fitIndices[, 2],
    xlab = "Soft Threshold (power)",
    ylab = "Scale Free Topology Model Fit, signed R^2",
    main = paste("Scale independence")
  )
  text(
    sft\$fitIndices[, 1],
    -sign(sft\$fitIndices[, 3]) * sft\$fitIndices[, 2],
    labels = powers,
    cex = cex1,
    col = "red"
  )
  abline(h = 0.90, col = "red")
  plot(
    sft\$fitIndices[, 1],
    sft\$fitIndices[, 5],
    xlab = "Soft Threshold (power)",
    ylab = "Mean Connectivity", type = "n", main = paste("Mean connectivity")
  )
  text(
    sft\$fitIndices[, 1],
    sft\$fitIndices[, 5],
    labels = powers,
    cex = cex1,
    col = "red"
    )
  dev.off()
  """
}

process wgcna_network {
  tag "${in_RData.fileName}"
  input:
  path in_RData

  output:
  path "*"

  script:
  """
  #! /usr/bin/env Rscript
  load('$in_RData')

  library(WGCNA)
  allowWGCNAThreads()

  netwk = blockwiseModules(
    inputMatrix,
    power = $params.power,
    TOMType = "unsigned",
    minModuleSize = 30,
    reassignThreshold = 0,
    mergeCutHeight = 0.25,
    numericLabels = TRUE,
    pamRespectsDendro = FALSE,
    saveTOMs = TRUE,
    saveTOMFileBase = "${in_RData.simpleName}TOM",
    verbose = 3)

  mergedColors = labels2colors(netwk\$colors)
  png("wgcna_modules.png", width=800, height=300)
  plotDendroAndColors(
    netwk\$dendrograms[[1]],
    mergedColors[netwk\$blockGenes[[1]]],
    "Module colors",
    dendroLabels = FALSE, hang = 0.03,
    addGuide = TRUE, guideHang = 0.05)
  dev.off()
  """
}

workflow {
  println("Hello world")

  if ( params.xlsx ) {
    rnaseq_ch = channel.fromPath(params.xlsx, checkIfExists:true) |
      read_xlsx |
      view {n -> "...created:  $params.outdir/$n.fileName"}
  } else {
    rnaseq_ch = channel.fromPath(params.file, checkIfExists:true) |
      read_delim |
      view {n -> "...created:  $params.outdir/$n.fileName"}
  }

  rnaseq_ch |
    plot_expression |
    view {n -> "...created:  $params.outdir/$n.fileName"}

  rnaseq_ch |
    prep_data |
    pick_soft_threshold |
    view {n -> "...created:  $params.outdir/$n.fileName"}

  prep_data.out |
    wgcna_network |
    flatten |
    view {n -> "...created:  $params.outdir/$n.fileName"}
}
