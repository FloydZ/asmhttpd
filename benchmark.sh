#!/bin/bash
make benchmark
operf -g -t -c  ./asmttpd ./web_root 8 8082 &
siege -b -t10s -c25 -i 192.168.1.236:8082
opannotate  --source --output-dir=./ --search-dirs=./
opreport --long-filenames --callgraph    