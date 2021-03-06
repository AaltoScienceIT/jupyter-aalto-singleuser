ARG VER_BASE
FROM aaltoscienceit/notebook-server-base:${VER_BASE}

USER root

RUN echo "tensorflow 2.3.*"                  >> /opt/conda/conda-meta/pinned && \
    echo "#tensorflow-tensorboard 1.5.*"     >> /opt/conda/conda-meta/pinned && \
    echo "keras 2.4.*"                       >> /opt/conda/conda-meta/pinned && \
    echo "pytorch 1.7.*"                     >> /opt/conda/conda-meta/pinned && \
    echo "torchvision 0.8.*"                 >> /opt/conda/conda-meta/pinned && \
    clean-layer.sh




# Custom installations
#RUN apt-get update && \
#    apt-get install -y --no-install-recommends \
#           ... \
#           && \
#    clean-layer.sh


# Custom installations
# arviz: bayesian data analysis
# cma: ??
# folium: BE remote sensing course
# geopandas: BE remote sensing course
# igraph: complex networks (general)
# keras: general use (for gpu, keras-gpu)
# librarosa: datasci2018
# networkx: complex networks (general)
# nose: mlbp2018
# owslib: mlpython
# plotchecker: for nbgrader, mlbp2018
# plotly: student request
# pydotplus - dsfb2018 instructor request
# pydub: ???
# pytorch: general use
# pystan: general use, bayes course (updated prompt_toolkit needed as dependency)
# rasterio: BE remote sensing course
# scikit-learn: mlbp2018
# tensorflow, tensorflow-tensorboard (general use)
# cvxopt       - mlkern2019
# nbstripout   - generic package
# nltk         -  datasci2019  (use conda  when upgrading)
# lapack       - dependency for cvxpy
# cvxpy        - mlkern2019
# gpflow       - special course Gaussian Processes, 2019 (pinned to 2.0.0rc1 to force tf2.0 compat)
# bcolz        - introai2019
# tqdm         - introai2019
# qiskit       - Introduction to Quantum Technologies, Matti Raasakka, RT#14866
# wordcloud - datasci2019
# geopy - datasci2019
# imbalanced-learn (student request)
# opencv: mlpython
# configargparse: deeplearn2020, also generally useful
# ortools:   ai2020
RUN \
    conda config --add channels conda-forge && \
    conda install \
        networkx \
        nose \
        pandas-datareader \
        plotly \
        pydotplus \
        scikit-learn \
        arviz \
        folium \
        python-igraph \
        feather-format \
        librosa \
        bcolz \
        tqdm \
        wordcloud \
        geopy \
        rasterio \
        geopandas \
        lapack \
        mlxtend \
        scikit-plot \
        imbalanced-learn \
        nltk \
        opencv \
        owslib \
        && \
    pip install --no-cache-dir \
        plotchecker \
        gpflow==2.0.0rc1 \
        calysto \
        cma \
        cvxopt \
        cvxpy \
        metakernel \
        pydub \
        qiskit \
        configargparse \
        geoplotlib \
        ipympl \
        ortools \
        && \
    clean-layer.sh
# Currently non-functional packages:
#   geopandas (conda-forge)
#   rasterio (conda-forge)

## TODO: Combine layers
    # Installing from pip because the tensorflow and tensorboard versions found
    # from the anaconda repos don't support python 3.7 yet
RUN \
    set -x && \
    conda config --system --set channel_priority flexible && \
    conda install \
        pystan prompt_toolkit \
        && \
    pip install --no-cache-dir \
        keras==2.4.* \
        tensorflow==2.3.* \
        tensorboard \
        tensorflow-hub \
        && \
    clean-layer.sh
RUN conda install --freeze-installed -c pytorch \
        pytorch==1.7.* \
        torchtext \
        torchvision==0.8.* \
        && \
    clean-layer.sh

# To move to the above
# mne: gabs2021
# rpy2: dsfbii
# shap: dsfbii
# lifeline: dsfbii
# pycox: dsfbii
# pysurvival: dsfbii
# scikit-survival: dsfbii
# beautifulsoup4: bdaaccounting
# xlsxwriter: bdaaccounting
# xlwt: bdaaccounting
RUN \
    conda install --freeze-installed \
        beautifulsoup4 \
        lifelines \
        rpy2 \
        shap \
        xlsxwriter \
        xlwt \
        && \
    pip install --no-cache-dir \
        mne \
        pycox \
        pysurvival \
        scikit-survival \
        && \
    clean-layer.sh


#RUN \
#    conda install --freeze-installed \
#        && \
#    clean-layer.sh

#RUN pip install --no-cache-dir \
#        && \
#    clean-layer.sh

# Update nbgrader
RUN \
    pip install --force --no-deps --upgrade --no-cache-dir \
        git+https://github.com/AaltoSciComp/nbgrader@live-2020 \
        'nbconvert<6' && \
    clean-layer.sh

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends \
           sudo \
           && \
    clean-layer.sh


# gensim: bdaaccounting
# pdfplumber: bdaaccounting
# pyodbc: bdaaccounting
# pmdarima: bdaaccounting
# tweepy: bdaaccounting
RUN \
    apt-get update && \
    apt-get upgrade -y --no-install-recommends \
        unixodbc-dev \
        && \
    pip install \
        gensim \
        pdfplumber \
        pyodbc \
        pmdarima \
        tweepy \
        && \
    clean-layer.sh
RUN \
    conda install --freeze-installed \
        freetds \
        && \
    echo [FreeTDS] >> /etc/odbcinst.ini && \
    echo Description=FreeTDS Driver >> /etc/odbcinst.ini && \
    echo Driver=/opt/conda/lib/libtdsodbc.so >> /etc/odbcinst.ini && \
    echo Setup=/opt/conda/lib/libtdsS.so >> /etc/odbcinst.ini && \
    clean-layer.sh

RUN pip install --no-cache-dir \
        sklearn-pandas \
        https://github.com/AntoinePassemiers/Lexicon-Based-Sentiment-Analysis/archive/283a2c819016e9a90d408bc82c6edbcd4104be9c.zip \
        && \
    clean-layer.sh


# ========================================

# Fix nbgrader permissions problem
RUN \
    sed -i "s@assert '0600' ==.*@assert stat.S_IMODE(os.stat(fname).st_mode) \& 0o77 == 0@" /opt/conda/lib/python3.8/site-packages/jupyter_client/connect.py

ENV CC=clang CXX=clang++


# Duplicate of base, but hooks can update frequently and are small so
# put them last.
COPY hooks/ scripts/ /usr/local/bin/
RUN chmod a+rx /usr/local/bin/*.sh

USER $NB_UID
