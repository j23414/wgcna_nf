# wgcna_nf

Attempt a non-bash pipeline in nextflow. In this case, this nextflow script is wrapping the R wgcna pipeline.

```
$ nextflow run j23414/wgcna_nf -r main --help

N E X T F L O W  ~  version 20.07.1
Launching `main.nf` [nasty_leavitt] - revision: 88e77ac875
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
```


**Main findings** of using R processes (instead of bash processes)

* Pass data between R processes via RData files

  ```
  load("input.RData")                        # <- load in prior data
  # ... R commands here
  save(data1, data2, data3, file = "output.RData")  #<- save output data
  ```
  
### Tutorial

Fetch the WGCNA Tutorial dataset

```
wget https://horvath.genetics.ucla.edu/html/CoexpressionNetwork/Rpackages/WGCNA/Tutorials/FemaleLiver-Data.zip
unzip FemaleLiver-Data.zip

#> Archive:  FemaleLiver-Data.zip
#>  inflating: ClinicalTraits.csv      
#>  inflating: GeneAnnotation.csv      
#>  inflating: LiverFemale3600.csv 
```

Run pipeline on dataset

```
nextflow run main.nf --file LiverFemale3600.csv --delim ','

#> N E X T F L O W  ~  version 20.07.1
#> Launching `main.nf` [compassionate_bartik] - revision: abc410b4a8
#> Hello world
#> executor >  local (1)
#> [ab/f35e1a] process > read_delim (LiverFemale3600.csv) [100%] 1 of 1 ✔
#> /Users/jenchang/Desktop/2020-10-14/wgcna_nf/work/ab/f35e1a63f80dc3518942face33f739/LiverFemale3600.RData
```
