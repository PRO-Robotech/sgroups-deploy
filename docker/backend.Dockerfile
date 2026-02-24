FROM golang:1.25 AS builder
WORKDIR /workspace
COPY sgroups/ sgroups/
WORKDIR /workspace/sgroups
RUN go mod download && \
    CGO_ENABLED=0 GOOS=linux go build -o /sg-server ./cmd/sg-server

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /sg-server /sg-server
USER 65534:65534
ENTRYPOINT ["/sg-server"]
