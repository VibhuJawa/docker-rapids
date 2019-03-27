docker run --runtime=nvidia --rm -it -p 7888:7888 -p 7787:7787 -p 7786:7786  -p 7800:7800 \
-e NVIDIA_VISIBLE_DEVICES=1,2,3,4,5,6,7 \
-it rapids
