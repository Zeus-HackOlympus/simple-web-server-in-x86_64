# Simple web server in x86\_64 

This is a simple web server written in x86\_64 assembly. Currently it supports only 2 HTTP requests - GET and POST.  

### Performance 

On average it handles 100 random HTTP GET and POST request in 0.109 seconds.

###  Installation 
1. Just use make. 

```
make
``` 

### To test 

I have made a `test.py` file. It will make random GET and POST requests and server will handle them on it's own. Run `test.py` along with server to see results.

### Demo Video

[![asciicast](https://asciinema.org/a/548826.svg)](https://asciinema.org/a/548826)
