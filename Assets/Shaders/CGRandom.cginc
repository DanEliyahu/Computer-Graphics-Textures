#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float2 values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [2]=====o==[3] (this is the rigth order)
//         |
//         t
//         |
// [0]=====o==[1]
//
float bicubicInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float2 values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * t * (6.0 * t * t - 15.0 * t + 10.0); //biquintic Interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float3 values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float v[8], float3 t)
{
    float3 u = t * t * t * (6.0 * t * t - 15.0 * t + 10.0); //biquintic Interpolation
    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);
    float x3 = lerp(v[4], v[5], u.x);
    float x4 = lerp(v[6], v[7], u.x);
    // Interpolate in the y direction 
    float y1 = lerp(x1, x2, u.y);
    float y2 = lerp(x3, x4, u.y);
    // Interpolate in the z direction 
    return lerp(y1, y2, u.z);
   
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    
    //getting the grid corners (must be integers) 

    float leftX = floor(c.x);
    float rightX = leftX + 1;
    float lowerY = floor(c.y);
    float upperY = lowerY + 1;
    /// calculateing random noise for each corner 
    float2 leftLow = float2(random2(float2(leftX, lowerY)).x, 0); // Ignoring the last compoment   
    float2 leftUp = float2(random2(float2(leftX, upperY)).x, 0);
    float2 rightUP = float2(random2(float2(rightX, upperY)).x, 0);
    float2 rightLow = float2(random2(float2(rightX, lowerY)).x, 0);
    float2 v[4] = { leftLow, rightLow
    ,leftUp, rightUP};
    return bicubicInterpolation(v, float2((c.x - leftX), (c.y - lowerY))); // returning the interpolation we send the fraction part of the point c to enter the 
    //grid boundries 
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{ 
    // this part is like the value noise to get the corners 
    float leftX = floor(c.x);
    float rightX = leftX + 1;
    float lowerY = floor(c.y);
    float upperY = lowerY + 1;
    float2 leftLow = random2(float2(leftX, lowerY)); // Ignoring the last compoment   
    float2 leftUp = random2(float2(leftX, upperY));
    float2 rightUP =random2(float2(rightX, upperY));
    float2 rightLow = random2(float2(rightX, lowerY));
    // add the vectors from each corners to the giving point c 
    float2 leftLowVector = c-float2(leftX, lowerY); // vectors from the  corners  to the point
    float2 leftUpVector = c-float2(leftX, upperY);
    float2 rightUPVector = c-float2(rightX, upperY);
    float2 rightLowVector = c-float2(rightX, lowerY);
    // calculate the value of each dot product and then interpolating the values with the frac part of c 
    float2 c0 = float2(dot(leftLowVector, leftLow), 0);
    float2 c1 = float2(dot(rightLowVector, rightLow), 0);
    float2 c2 = float2(dot(leftUpVector, leftUp), 0);
    float2 c3 = float2(dot(rightUPVector, rightUP), 0);
    float2 v[4] =
    {c0, c1
    , c2,c3};
    return biquinticInterpolation(v, float2((c.x - leftX), (c.y - lowerY)));
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{   // same idea as perlid 2d this time we take 3d grid (cube ) and calcute all the corners of the cuve (2^3=8)                   
    float leftX = floor(c.x);
    float rightX = leftX + 1;
    float lowerY = floor(c.y);
    float upperY = lowerY + 1;
    float backZ = floor(c.z);
    float frontZ = backZ + 1;
    float3 leftLowBack = random3(float3(leftX, lowerY,backZ));    
    float3 rightLowBack = random3(float3(rightX, lowerY,backZ));
    float3 leftUpBack = random3(float3(leftX, upperY, backZ));
    float3 rightUpBack = random3(float3(rightX, upperY, backZ));
    float3 leftLowFront = random3(float3(leftX, lowerY, frontZ)); 
    float3 rightLowFront = random3(float3(rightX, lowerY, frontZ));
    float3 leftUpFront = random3(float3(leftX, upperY, frontZ));
    float3 rightUpFront = random3(float3(rightX, upperY, frontZ));
     // add the vectors from each corners to the giving point c 
    float3 leftLowBackVector = c-float3(leftX, lowerY, backZ);  
    float3 rightLowBackVector = c - float3(rightX, lowerY, backZ);
    float3 leftUpBackVector = c- float3(leftX, upperY, backZ);
    float3 rightUpBackVector = c-float3(rightX, upperY, backZ);
    float3 leftLowFrontVector = c- float3(leftX, lowerY, frontZ);  
    float3 rightLowFrontVector = c- float3(rightX, lowerY, frontZ);
    float3 leftUpFrontVector = c-float3(leftX, upperY, frontZ);
    float3 rightUpFrontVector = c-float3(rightX, upperY, frontZ);
    // calculate the value of each dot product and then interpolating the values with the frac part of c 
    float c0 = dot(leftLowBackVector, leftLowBack);
    float c1 = dot(rightLowBackVector, rightLowBack);
    float c2 = dot(leftUpBackVector, leftUpBack);
    float c3 = dot(rightUpBackVector, rightUpBack);
    float c4 = dot(leftLowFrontVector, leftLowFront);
    float c5 = dot(rightLowFrontVector, rightLowFront);
    float c6 = dot(leftUpFrontVector, leftUpFront);
    float c7 = dot(rightUpFrontVector, rightUpFront);
    float v[8] = { c0, c1, c2, c3, c4, c5, c6, c7 };
    return triquinticInterpolation(v, float3((c.x - leftX), (c.y - lowerY), (c.z - backZ)));
}


#endif // CG_RANDOM_INCLUDED
