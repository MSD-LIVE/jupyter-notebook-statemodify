# Extend the MSD-LIVE Centos 7 Jupyter Notebook container
# Use a mutli-stage build to keep the final image small
FROM ghcr.io/msd-live/jupyter/python-notebook:latest as build-image
USER root

# make a directory to store builds in 
RUN mkdir -p /usr/src/statemodify

# Remove all the .git folders so they are not included in the final image.  Some of them
# were really huge.
RUN cd /usr/src/statemodify \
    && git clone --single-branch --branch main https://github.com/IMMM-SFA/statemodify.git
RUN rm -rf /usr/src/statemodify/statemodify/.git

# for Gunnison and San Juan Dolores
RUN cd /usr/src/statemodify \
    && git clone https://github.com/OpenCDSS/cdss-app-statemod-fortran.git statemod_gunnison_sjd
RUN rm -rf /usr/src/statemodify/statemod_gunnison_sjd/.git

# for Upper Colorado
RUN cd /usr/src/statemodify \
    && git clone https://github.com/rg727/cdss-app-statemod-fortran.git statemod_upper_co
RUN rm -rf /usr/src/statemodify/statemod_upper_co/.git


FROM ghcr.io/msd-live/jupyter/python-notebook:latest as main-image
USER root

# Add core libraries needed to run Fortran model
RUN apt -y update && apt -y install gfortran make file

COPY --from=build-image "/usr/src/statemodify" "/usr/src/statemodify"

RUN cd /usr/src/statemodify/statemodify && pip install -e .

# Before building, we have to update the makefiles because there are problems that 
# prevent it from compiling (search for MSD-LIVE in the makefiles for more details)
COPY ./makefile.statemod_gunnison_sjd /usr/src/statemodify/statemod_gunnison_sjd/src/main/fortran/makefile
COPY ./makefile.statemod_upper_co /usr/src/statemodify/statemod_upper_co/src/main/fortran/makefile

# for Gunnison and San Juan Dolores
RUN cd /usr/src/statemodify/statemod_gunnison_sjd/src/main/fortran \
    && sed -i.bak s/-static//g makefile \
    && make veryclean \
    && make statemod; exit 0

# for Upper Colorado
RUN cd /usr/src/statemodify/statemod_upper_co/src/main/fortran \
    && sed -i.bak s/-static//g makefile \
    && make veryclean \
    && make statemod; exit 0

RUN chmod -R 777 /usr/src/statemodify

# install the msdlive plugin in order for the msdlive labs extension to discover it via entry points and 
# copy the files to users home dir instead of using the exisitng symlink 
COPY msdlive_hooks /srv/jupyter/extensions/msdlive_hooks
RUN pip install /srv/jupyter/extensions/msdlive_hooks

# copy the notebooks to the container
COPY notebooks /home/jovyan/notebooks