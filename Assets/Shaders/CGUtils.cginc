#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653
// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    // as seen in TA we transfer to spherical coordinates to calculate uv coords
    float theta = atan2(pos.z, pos.x);
    float r = sqrt(pos.x * pos.x + pos.y * pos.y + pos.z * pos.z);
    float phi = acos(pos.y / r);
    return float2(0.5 + (theta) / (2 * PI), 1 - phi / PI);;
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
	float3 h = normalize((l + v));
    fixed4 ambient = ambientIntensity * albedo;
	fixed4 diffuse = max(dot(l, n), 0) * albedo;
	fixed4 specular = pow(max(0, dot(n, h)), shininess) * specularity;
    return ambient+diffuse+specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{  
    // sample the height map at the given uv coords and at an epsilon in each direction u and v
    // in order to get an approximation of the derivative to calculate the bump mapped normal
    fixed4 f_pPlusdu = tex2D(i.heightMap, float2(i.uv.x + i.du, i.uv.y));
    fixed4 f_pPlusdv = tex2D(i.heightMap, float2(i.uv.x, i.uv.y + i.dv));
    fixed4 f_p = tex2D(i.heightMap, i.uv);
    fixed fdu = (f_pPlusdu - f_p) / i.du;
    fixed fdv = (f_pPlusdv - f_p) / i.dv;
    float3 nh = normalize(float3(i.bumpScale * fdu * (-1), i.bumpScale * fdv * (-1), 1));
    float3 b = normalize(cross(i.tangent, i.normal));  // find the bitangent vector
    float3 newNormalWorld = normalize((i.tangent * nh.x) + (i.normal * nh.z) + (b * nh.y)); // transfer the new normal to world coordinates
    return newNormalWorld;
}


#endif // CG_UTILS_INCLUDED