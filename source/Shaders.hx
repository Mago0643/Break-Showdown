package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.system.FlxAssets.FlxShader;

/**
* `From:` https://www.shadertoy.com/view/4lXXWn
*/
class BlurEffect
{
    public var shad(default,never) = new BlurShader();

    public function new(amount:Float = 0.0)
    {
        shad.blurAmount.value = [amount];
        shad.iTime.value = [0];
    }
}

/**
* By https://www.shadertoy.com/view/td2GzW
*
* Original is https://www.shadertoy.com/view/4s2GRR, i think.
*/
class FisheyeEffect
{
    public var shader(default, never):FisheyeShader = new FisheyeShader();

    public function new()
    {
        shader.center.value = [FlxG.width / 2];
        shader.power.value = [0.0];
        shader.iResolution.value = [FlxG.width, FlxG.height];
    }
}

enum GlitchDirection
{
    LEFT_RIGHT;
    UP_DOWN;
}

/**
* By Lego0_77
*/
class SimpleGlitchEffect
{
    public var shader(default, never) = new SimpleGlitchShader();

    public function new(?direction:GlitchDirection = LEFT_RIGHT, ?offset:Float = 0.0)
    {
        if (direction == LEFT_RIGHT)
        {
            shader.direction.value = [0];
        } else {
            shader.direction.value = [1];
        }

        shader.offset.value = [offset];
    }
}

/**
* `From:` https://www.shadertoy.com/view/4lXXWn
*/
class BlurShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float iTime;
        uniform float blurAmount;

        vec3 draw(vec2 uv) {
            return texture(bitmap,vec2(uv.x,1.-uv.y)).rgb;   
            //return texture(iChannel0,uv).rgb;  
        }
        
        float grid(float var, float size) {
            return floor(var*size)/size;
        }
        
        float rand(vec2 co){
            return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
        }
        
        void main()
        {
            float time = iTime;
            vec2 uv = openfl_TextureCoordv;
            uv.y = 1.0-uv.y;
            
            float bluramount = blurAmount;
        
            //float dists = 5.;
            vec3 blurred_image = vec3(0.);
            #define repeats 60.
            for (float i = 0.; i < repeats; i++) { 
                //Older:
                //vec2 q = vec2(cos(degrees((grid(i,dists)/repeats)*360.)),sin(degrees((grid(i,dists)/repeats)*360.))) * (1./(1.+mod(i,dists)));
                vec2 q = vec2(cos(degrees((i/repeats)*360.)),sin(degrees((i/repeats)*360.))) *  (rand(vec2(i,uv.x+uv.y))+bluramount); 
                vec2 uv2 = uv+(q*bluramount);
                blurred_image += draw(uv2)/2.;
                //One more to hide the noise.
                q = vec2(cos(degrees((i/repeats)*360.)),sin(degrees((i/repeats)*360.))) *  (rand(vec2(i+2.,uv.x+uv.y+24.))+bluramount); 
                uv2 = uv+(q*bluramount);
                blurred_image += draw(uv2)/2.;
            }
            blurred_image /= repeats;
                
            gl_FragColor = vec4(blurred_image,1.0);
        }
    ')
    public function new() {super();}
}

/**
* By https://www.shadertoy.com/view/td2GzW
*
* Original is https://www.shadertoy.com/view/4s2GRR, i think.
* 
* (Original is not working in Haxe for some reason)
*/
class FisheyeShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header

    uniform vec2 iResolution;
    uniform float center;
    uniform float power;

    //Inspired by http://stackoverflow.com/questions/6030814/add-fisheye-effect-to-images-at-runtime-using-opengl-es
    void main()
    {
        vec2 p = gl_FragCoord.xy / iResolution.x;//normalized coords with some cheat
                                                                //(assume 1:1 prop)
        float prop = iResolution.x / iResolution.y;//screen proroption
        vec2 m = vec2(0.5, 0.5 / prop);//center coords
        vec2 d = p - m;//vector from center to current fragment
        float r = sqrt(dot(d, d)); // distance of pixel from center

        float bind;//radius of 1:1 effect
        if (power > 0.0) 
            bind = sqrt(dot(m, m));//stick to corners
        else {if (prop < 1.0) 
            bind = m.x; 
        else 
            bind = m.y;}//stick to borders

        //Weird formulas
        vec2 uv;
        if (power > 0.0)//fisheye
            uv = m + normalize(d) * tan(r * power) * bind / tan( bind * power);
        else if (power < 0.0)//antifisheye
            uv = m + normalize(d) * atan(r * -power * 10.0) * bind / atan(-power * bind * 10.0);
        else uv = p;//no effect for power = 1.0
            
        uv.y *= prop;
        
        // inverted
        //vec3 col = texture2D(bitmap, vec2(uv.x, 1.0 - uv.y)).rgb;//Second part of cheat
                                                        //for round effect, not elliptical
        gl_FragColor = texture2D(bitmap, uv);
    }')
    public function new(){super();}
}

/**
* By Lego0_77
*/
class SimpleGlitchShader extends FlxShader
{
    @:glFragmentSource('
    #pragma header

    // 0 is width,
    // 1 is height.
    uniform int direction;
    uniform float offset;

    void main()
    {
        vec2 uv = openfl_TextureCoordv;
        float r = 0.0; float g = 0.0; float b = 0.0; float a = 1.0;
        
        if (direction == 0)
        {
            r = texture2D(bitmap, vec2(uv.x - offset, uv.y)).r;
            g = texture2D(bitmap, vec2(uv.x, uv.y)).g;
            b = texture2D(bitmap, vec2(uv.x + offset, uv.y)).b;
            a = texture2D(bitmap, uv).a;
        } else {
            r = texture2D(bitmap, vec2(uv.x, uv.y - offset)).r;
            g = texture2D(bitmap, vec2(uv.x, uv.y)).g;
            b = texture2D(bitmap, vec2(uv.x, uv.y + offset)).b;
            a = texture2D(bitmap, uv).a;
        }

        gl_FragColor = vec4(r,g,b,a);
    }')
    public function new(){super();}
}