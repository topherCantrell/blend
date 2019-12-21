
import java.io.*;
import java.util.*;

public class Processor
{
    
    public static void main(List code) throws Exception 
    {
        
        for(int x=0;x<code.size();++x) {      
            Line a = (Line)code.get(x);
            String s = a.rawNoComment.trim();               
            if(s.startsWith("processor")) {                  
                String proc = s.substring(10).trim();
                boolean b = BlendConfig.reInit(proc);
                if(!b) {
                    throw new RuntimeException("Unknown processor: "+s);
                }
                a.commentOutWholeLine();
                return;
            }
        }
    }
    
}
