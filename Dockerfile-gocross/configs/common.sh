unset GOARCH GCCGO GOPATH GOROOT LD_LIBRARY_PATH CGO_ENABLED


if [ -z "$OLDPATH" ]; then
        export OLDPATH=$PATH
        export PATH=/opt/golang/configs/bin:$PATH
fi
export GOOS="linux"
