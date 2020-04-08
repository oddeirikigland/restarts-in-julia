FROM julia:1.4.0-buster
COPY . /app
WORKDIR /app
CMD julia src/Main.jl