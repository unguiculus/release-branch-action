FROM alpine:3.10

LABEL maintainer="Reinhard Nägele <unguiculus@gmail.com>"

RUN apk --update --no-cache add \
    bash \
    ca-certificates \
    git

COPY release_branch.sh /release_branch.sh

ENTRYPOINT ["/release_branch.sh"]
CMD ["--help"]
