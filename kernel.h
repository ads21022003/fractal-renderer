#pragma once
#ifndef KERNEL_H
#define KERNEL_H

struct uchar4;
struct double2;
void kernelLauncher(uchar4 * d_out, int w, int h, double2 pos, float zoom,double2 offset);

#endif