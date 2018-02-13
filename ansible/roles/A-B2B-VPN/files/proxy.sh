# Configure A Proxy server
export NO_PROXY=localhost,127.0.0.1,.a.aws.int,169.254.169.254
export HTTP_PROXY=http://162.95.240.240:8080
export HTTPS_PROXY=${HTTP_PROXY}
