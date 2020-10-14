FROM rocker/r-ver:latest
MAINTAINER Jennifer Chang "jenchang@iastate.edu"

RUN apt-get update && apt-get install
RUN R -e "update.packages(ask=F);"
RUN R -e "install.packages(c("tidyverse", "WGCNA"))

CMD ["R"]