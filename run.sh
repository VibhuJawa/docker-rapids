docker run  -p 7888:7888 -p 7787:7787 \
    -v /data:/data \
    -v /home/dev/projects/dev-notebooks:/notebooks \
    -it rapids-strings
