# pull latest julia image
FROM julia:latest

# create dedicated user
RUN useradd --create-home --shell /bin/bash genie

# set up the app
RUN mkdir /home/genie/app
COPY . /home/genie/app
WORKDIR /home/genie/app

# configure permissions
RUN chown -R genie:genie /home/

RUN chmod +x bin/repl
RUN chmod +x bin/server
RUN chmod +x bin/runtask

# switch user
USER genie



# instantiate Julia packages
RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile(); "


# ports
EXPOSE 8000
EXPOSE 80

# set up app environment
ENV JULIA_DEPOT_PATH="/home/genie/.julia"
ENV GENIE_ENV="prod"
ENV GENIE_HOST="0.0.0.0"
ENV PORT="8000"
ENV WSPORT="8000"
ENV EARLYBIND="true"
ENV HOSTNAME="0.0.0.0"
ENV HOST="0.0.0.0"


# run app
CMD ["bin/server"]

# or maybe include a Julia file
# CMD julia -e 'using Pkg; Pkg.activate("."); include("IrisClustering.jl"); '
