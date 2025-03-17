FROM rocker/rstudio:4.4.2

# Declare build argument (Used by Docker BuildKit)
ARG TARGETARCH

# Set environment variables early
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${TARGETARCH}/
ENV R_LIBS_SITE="/usr/local/lib/R/site-library:/usr/lib/R/site-library"
ENV SPARK_HOME=/opt/spark
ENV PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"

# Install system dependencies and packages from requirements-bin.txt in one layer
COPY requirements-bin.txt ./
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        cmake \
        libhdf5-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libpng-dev \
        libxt-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libglpk40 \
        libgit2-dev \
        libgsl-dev \
        patch \
        libmagick++-dev \
        openjdk-11-jdk \
        ant \
        ca-certificates-java \
        gdal-bin \
        libudunits2-dev \
        libgdal-dev \
        libgeos-dev \
        maven && \
    cat requirements-bin.txt | xargs apt-get install -y -qq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Download and install Spark
RUN wget https://archive.apache.org/dist/spark/spark-3.5.5/spark-3.5.5-bin-hadoop3.tgz && \
    tar -xvzf spark-3.5.5-bin-hadoop3.tgz && \
    mv spark-3.5.5-bin-hadoop3 /opt/spark && \
    rm spark-3.5.5-bin-hadoop3.tgz

# Install R packages (if needed) via Rscript
COPY requirements-src.R ./
RUN Rscript requirements-src.R

RUN Rscript -e "if (!requireNamespace('devtools', quietly = TRUE)) install.packages('devtools', repos='https://cran.rstudio.com'); devtools::install_github('apache/sedona/R')"

# Download Apache Sedona jars for Sedona version 1.7.0 (including sedona-viz)
RUN wget -q https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.5_2.12/1.7.0/sedona-spark-shaded-3.5_2.12-1.7.0.jar \
         -O $SPARK_HOME/jars/sedona-spark-shaded-3.5_2.12-1.7.0.jar && \
    wget -q https://repo1.maven.org/maven2/org/apache/sedona/sedona-viz-3.4_2.12/1.4.1/sedona-viz-3.4_2.12-1.4.1.jar \
         -O $SPARK_HOME/jars/sedona-viz-3.4_2.12-1.4.1.jar && \
    wget -q https://repo.maven.apache.org/maven2/org/datasyslab/geotools-wrapper/1.7.0-28.5/geotools-wrapper-1.7.0-28.5.jar \
         -O $SPARK_HOME/jars/geotools-wrapper-1.7.0-28.5.jar 

# Copy rstudio-prefs.json
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/

WORKDIR /home/rstudio
