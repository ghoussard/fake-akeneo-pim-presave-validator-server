FROM golang:1.24 AS builder

WORKDIR /app
COPY go.mod ./
COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM gcr.io/distroless/static-debian12

COPY --from=builder /app/server /server

ENTRYPOINT ["/server"]
