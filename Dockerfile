FROM hugomods/hugo:0.124.0-exts AS builder
WORKDIR /src
COPY . .
RUN hugo --minify

FROM scratch AS output
COPY --from=builder /src/public/ /