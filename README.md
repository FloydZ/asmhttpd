asmttpd
=======
Web server for Linux written in amd64 assembly.

Features:
* Multi-threaded.
* No libraries required ( only 64-bit Linux ).
* Very small binary, under 6 KB.  ==> Nicht mehr Momentan in Debug Mode
* Quite fast.

What works:
* Serving files from specified document root.
* 200, 206, 404, 400, 413, 416
* Content-types: xml, html, xhtml, gif, png, jpeg, css, js, and octet-stream.
  
Planned Features:
* Directory listing.
* HEAD support.

Current Limitations / Known Issues
=======
* Sendfile can hang if GET is cancelled.

Installation
=======

Run `make` or `make release` for non-debug version. You can also run a small benchmark script via `./banchmark.sh`
You will need `yasm` installed. If you want to benchmark `asmhttpf` you need addionaliy `operf` and `siege` installed on your server.

Usage
=======
`./asmttpd /path/to/web_root 8 8080`
`sudo ./asmttpd /path/to/web_root 8 80`
`./asmttpd /path/to/web_root numThreads Port`

Changes
=======
2014-07-14 : asmttpd - 0.3

* Forked from (nemasu)[https://github.com/nemasu/asmttpd]
