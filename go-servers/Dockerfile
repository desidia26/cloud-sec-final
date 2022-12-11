## Build
FROM golang:1.16-buster AS build
ARG SERVER_NAME
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY *.go ./
RUN go build -o /${SERVER_NAME}

## Deploy
FROM gcr.io/distroless/base-debian10
ARG SERVER_NAME
WORKDIR /
COPY --from=build /${SERVER_NAME} /docker_entrypoint
EXPOSE 8080
USER nonroot:nonroot

ENTRYPOINT ["/docker_entrypoint"]