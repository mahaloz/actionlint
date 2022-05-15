from golang:1.17 as builder

RUN apt update && apt install clang -y

COPY . /go/actionlint

# install source of target
RUN mkdir ~/gopath && \
    export GOPATH="$HOME/gopath" && \
    export PATH="$PATH:$GOPATH/bin" && \
    cd /go/actionlint/fuzz && \
    go install -tags production github.com/rhysd/actionlint && \
    go get github.com/dvyukov/go-fuzz/go-fuzz github.com/dvyukov/go-fuzz/go-fuzz-build && \
    go-fuzz-build -libfuzzer --func FuzzExprParse -o fuzz_actionlint_expr_parser.a . && \
    clang -fsanitize=fuzzer fuzz_actionlint_expr_parser.a  -o fuzz_actionlint_expr_parser && \
    cp fuzz_actionlint_expr_parser /fuzz_actionlint_expr_parser

FROM golang:1.17
COPY --from=builder /fuzz_actionlint_expr_parser /
