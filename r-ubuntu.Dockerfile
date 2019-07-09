ARG VER_BASE
FROM aaltoscienceit/notebook-server-base:${VER_BASE}

## R support

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        ed \
        fonts-dejavu \
        tzdata \
        gfortran \
        gzip \
        libblas-dev \
        libgit2-dev \
        libssl-dev \
        libopenblas-dev \
        liblapack-dev \
        r-base && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

#libnlopt-dev --> NO, not compatible

#libprce2-dev
#libbz2-dev
#liblzma-dev

ARG CRAN_URL=https://cran.microsoft.com/snapshot/2018-10-02/

RUN \
    Rscript -e "install.packages(c('repr','IRdisplay','evaluate','crayon','pbdZMQ','devtools','uuid','digest'), repos='${CRAN_URL}', clean=TRUE)" && \
    Rscript -e "devtools::install_github('IRkernel/IRkernel')" && \
    Rscript -e 'IRkernel::installspec(user = FALSE)'
RUN jupyter kernelspec remove -f python3

# Packages from jupyter r-notebook
RUN \
    Rscript -e "install.packages(c('plyr', 'devtools', 'tidyverse', 'shiny', 'markdown', 'forecast', 'RSQLite', 'reshape2', 'nycflights13', 'caret', 'RCurl', 'crayon', 'randomForest', 'htmltools', 'sparklyr', 'htmlwidgets', 'hexbin'), repos='${CRAN_URL}', clean=TRUE)" && \
    fix-permissions /usr/local/lib/R/site-library

#
# Course setup
#

# Packages needed for bayesian macheine learning course
RUN \
    Rscript -e "install.packages(c('nloptr', 'bayesplot', 'rstan', 'rstanarm', 'shinystan', 'loo', 'brms', 'GGally', 'MASS', 'coda', 'gridBase', 'gridExtra', 'here', 'projpred'), repos='${CRAN_URL}', clean=TRUE)" && \
    fix-permissions /usr/local/lib/R/site-library

# Try to disable Python kernel
# https://github.com/jupyter/jupyter_client/issues/144
RUN rm -r /home/$NB_USER/.local/ && \
    echo 'c.NotebookApp.iopub_data_rate_limit = .8*2**20' >> /etc/jupyter/jupyter_notebook_config.py && \
    echo 'c.LabApp.iopub_data_rate_limit = .8*2**20' >> /etc/jupyter/jupyter_notebook_config.py && \
    echo "c.KernelSpecManager.whitelist={'ir'}" >> /etc/jupyter/jupyter_notebook_config.py

# Set default R compiler to clang to save memory.
RUN echo "CC=clang"     >> /usr/lib/R/etc/Makevars && \
    echo "CXX=clang++"  >> /usr/lib/R/etc/Makevars
ENV R_MAKEVARS_SITE /usr/lib/R/etc/Makevars

#
# Rstudio
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libapparmor1 \
        libedit2 \
        lsb-release \
        psmisc \
        libssl1.0.0 \
        && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

ENV RSTUDIO_PKG=rstudio-server-1.1.456-amd64.deb
# https://github.com/jupyterhub/nbrsessionproxy
RUN wget -q http://download2.rstudio.org/${RSTUDIO_PKG} && \
    dpkg -i ${RSTUDIO_PKG} && \
    rm ${RSTUDIO_PKG}

# Rstudio for jupyterlab
#   Viasat/nbrsessionproxy is a more up to date fork which is compatible with recent JL
RUN git clone https://github.com/Viasat/nbrsessionproxy /usr/local/nbrsessionproxy && \
    pip install -e /usr/local/nbrsessionproxy && \
    jupyter serverextension enable --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension install    --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension enable     --sys-prefix --py nbrsessionproxy && \
    jupyter labextension link /usr/local/nbrsessionproxy/jupyterlab-rsessionproxy && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    npm cache clean --force && \
    fix-permissions $CONDA_DIR /home/$NB_USER && \
    fix-permissions /usr/local/nbrsessionproxy/jupyterlab-rsessionproxy/ && \
    ln -s /usr/lib/rstudio-server/bin/rserver /usr/local/bin/

RUN sed -i -e "s/= gcc/= clang -flto=thin/" -e "s/= g++ /= clang++/" /usr/lib/R/etc/Makeconf

# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+x /usr/local/bin/*.sh

USER $NB_UID
