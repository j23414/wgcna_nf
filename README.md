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
  load(\"$input_RData\")                        # <- load in prior data
  # ... R commands here
  save(data1, data2, data3, file = \"${input_RData.simpleName}.RData\")  #<- save output data
  ```

* Remember to escape double quotation marks inside nextflow script blocks

### Tutorial

Fetch the WGCNA Tutorial dataset

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
#> exectuor > local (2)
[52/f3ab7e] process > read_delim (LiverFemale3600.csv) [100%] 1 of 1 ✔
[61/5947da] process > plot_expression (1)              [100%] 1 of 1 ✔
/Users/jenchang/Desktop/2020-10-14/wgcna_nf/work/61/5947da1252389a5b005fbeacab3c55/expression.png
```

**results/expression.png**

<img src="imgs/expression.png" alt="Girl in a jacket" />
