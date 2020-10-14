# wgcna_nf

Attempt a non-bash pipeline in nextflow

```
nextflow run j23414/wgcna_nf -r main --file my_rnaseq.csv --delim ','
```


**Main findings** of using R processes (instead of bash processes)

* Pass data between R processes via RData files

  ```
  load("input.RData")                        # <- load in prior data
  # ... R commands here
  save(data1, data2, data3, file = "output.RData")  #<- save output data
  ```
