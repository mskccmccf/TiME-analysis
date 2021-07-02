# TiME-analysis
Image and data analysis code for in vivo tumor-immune microenvironment project. 



[**bk-subtraction-tracking-filtering**](https://github.com/mskccmccf/TiME-analysis/tree/main/bk-subtraction-tracking-filtering): contains scripts used for performing nonlinear stabilization, cropping and background subtraction in Matlab and for batch processing movies in Fiji using Trackmate.



[**Time-Segmentation**](https://github.com/mskccmccf/TiME-analysis/tree/main/TIME-Segmentation): contains a python notebook for training a segmentation model for pixel-wise segmentation of RCM images of skin for patterns of "Tumor Micro Enviroment (TiME)"



[**Vessel-Segmentation**](https://github.com/mskccmccf/TiME-analysis/tree/main/Vessel-Segmentation): contains a Matlab script that takes a RCM videos at a given level and segments the vessels in the field of view. The video should preferably be free of lateral and axial (depth) motion. One can use image stack registration (stabilization) tools provided by [FIJI](https://imagej.net/software/fiji/) to correct for lateral motion. 

