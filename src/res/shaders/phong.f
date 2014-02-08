smooth in vec4 fragPosition;
smooth in vec2 uv;
smooth in vec3 normal;
uniform mat4 m, v, p, vInv;

out vec4 fragColor;

struct lightSource
{
    vec4 position;
    vec4 diffuse;
    vec4 specular;
    float constantAttenuation, linearAttenuation, quadraticAttenuation;
    float spotCutoff, spotExponent;
    vec3 spotDirection;
};

lightSource light0 = lightSource(
    vec4(0.0,1.0,2.0, 1.0),
    vec4(1.0,1.0,1.0, 1.0),
    vec4(1.0,1.0,1.0, 1.0),
    0.0, 1.0, 0.0,
    180.0, 0.0,
    vec3(0.0, 0.0, 0.0)
);

vec4 scene_ambient = vec4(0.2, 0.2, 0.2, 1.0);

struct material
{
    vec4 ambient;
    vec4 diffuse;
    vec4 specular;
    float shininess;
};

material frontMaterial = material(
    vec4(0.2, 0.2, 0.2, 1.0),
    vec4(1.0, 0.8, 0.8, 1.0),
    vec4(1.0, 1.0, 1.0, 1.0),
    5.0
);

void main(void)
{
    vec3 normalDirection = normalize(normal);
    vec3 viewDirection = normalize(vec3(vInv * vec4(0.0, 0.0, 0.0, 1.0) - fragPosition));
    vec3 lightDirection;
    float attenuation;

    if (0.0 == light0.position.w) // directional light?
    {
        attenuation = 1.0; // no attenuation
        lightDirection = normalize(vec3(light0.position));
    }
    else // point light or spotlight (or other kind of light)
    {
        vec3 positionToLightSource = vec3(light0.position - fragPosition);
        float distance = length(positionToLightSource);
        lightDirection = normalize(positionToLightSource);
        attenuation = 1.0 / (light0.constantAttenuation
         + light0.linearAttenuation * distance
         + light0.quadraticAttenuation * distance * distance);

        if (light0.spotCutoff <= 90.0) // spotlight?
        {
            float clampedCosine = max(0.0, dot(-lightDirection, light0.spotDirection));
            if (clampedCosine < cos(radians(light0.spotCutoff))) { // outside of spotlight cone?
                attenuation = 0.0;
            }
            else {
                attenuation = attenuation * pow(clampedCosine, light0.spotExponent);
            }
        }
    }

    vec3 ambientLighting = vec3(scene_ambient) * vec3(frontMaterial.ambient);

    vec3 diffuseReflection = attenuation
        * vec3(light0.diffuse) * vec3(frontMaterial.diffuse)
        * max(0.0, dot(normalDirection, lightDirection));

    vec3 specularReflection;
    if (dot(normalDirection, lightDirection) < 0.0) { // light source on the wrong side?
        specularReflection = vec3(0.0, 0.0, 0.0); // no specular reflection
    }
    else { // light source on the right side
        specularReflection = attenuation * vec3(light0.specular) * vec3(frontMaterial.specular)
            * pow(max(0.0, dot(reflect(-lightDirection, normalDirection), viewDirection)), frontMaterial.shininess);
    }

    fragColor = vec4(ambientLighting + diffuseReflection + specularReflection, 1.0);
}