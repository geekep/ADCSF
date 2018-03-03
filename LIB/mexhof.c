#include "mex.h"
#include <math.h>
#include <float.h>
#include <stdint.h>

uint_fast32_t mindist(double xr, double xi, double * binx, double * biny){
  uint_fast32_t k, bin;
  double zr,zy,z;
  double min_ = 1000000;
  for(k = 0; k < 10; k ++){
    zr = xr - binx[k];    
    zy = xi - biny[k];
    z = sqrt(zr*zr+zy*zy);    
    if(min_ > z){
      min_ = z;
      bin = k;
    }
  }
  return bin;
}

void L1norm(double *h){
  uint_fast8_t k;
  double r = 0;
  for(k = 0; k<5; k++){
    r += h[k];
  }
  for(k = 0; k<5; k++){
    h[k] = h[k] / r;
  }
}

void mexhof( double *xr, double *xi, uint_fast32_t N, double *h){
  uint_fast32_t  j,bin;
  double z;
  double g[10] = {0,0,0,0,0,0,0,0,0,0};
  double binx[10] = {1,0.809,0.309,-0.309,-0.809,-1,-0.809,-0.309,0.309,0.809};
  double biny[10] = {0,0.5878,0.9511,0.9511,0.5878,0,-0.5878,-0.9511,-0.9511,-0.5878};
  for(j = 0; j < N; j++){   
    z = sqrt(xr[j]*xr[j] + xi[j]*xi[j]) + DBL_MIN;
    bin = mindist(xr[j]/z, xi[j]/z, binx, biny);
    g[bin] += z;
  }
  h[0] = g[0] + g[5];
  h[1] = g[1] + g[6];
  h[2] = g[2] + g[7];
  h[3] = g[3] + g[8];
  h[4] = g[4] + g[9];
  L1norm(h);
}

void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
    uint_fast32_t  N = (uint_fast32_t )mxGetM(prhs[0]);
    double * xr = mxGetPr(prhs[0]);
    double * xi = mxGetPi(prhs[0]);
  
    plhs[0] = mxCreateDoubleMatrix(1,5,mxREAL);
    double * h = mxGetPr(plhs[0]);

    mexhof(xr, xi, N, h);
    return;
}

