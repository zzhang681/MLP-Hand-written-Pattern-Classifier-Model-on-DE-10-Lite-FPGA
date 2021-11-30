# MSEE_Project_EE297
A Project Proposal Presented to The faculty of the Department of Electrical Engineering San José State University

by Ziyin Zhang and Wen Zhi Qian
Project Advisor: Binh Le

## Multi-Layer Perceptron (MLP) Hand-wrtitten Pattern Number Recognition System On FPGA

Machine learning is one type of Artificial Intelligence applications and allows software applications to accurately predict outcomes with less human error and bias. Therefore, the suitable hardware used for this handwritten digit’s recognition system is also aiming at maximizing computing power. The classical electrical engineering topics are not only covering circuit designs, but also impacted by the digital transformation with the newly developed embedded system FPGA with its inherent parallelism processing. In this project, Intel Max series DE10-lite FPGA chip is used to perform the MLP calculation with accessing an on-board external SDRAM chip as storing unit. To eliminate the complex process of data type conversion on FPGA, there is a Avalon Memory Mapped Interface (Avalon-MM) introduced by using Intel Platform Designer System integration tool.

Avalon -MM interface is an address-based read/write interface typical of host-agent connections. Here we are using it to connects several IP components together and allow trained weight files and input images to be send directly from a host computer to the SDRAM through the JTAG to Avalon-MM component. The contents of the SDRAM are accessed through an External Bus to Avalon Bridge.

One could also add other display component such as VGA controller and VGA to the figure 1’s system. This will require additional understanding of VGA display generation using FPGA beyond the scope of this course.

The complete code will be available on GitHub for contributing to the community.

Figure 1. de10lite-hdl-master Top-Level Design Block Diagram


