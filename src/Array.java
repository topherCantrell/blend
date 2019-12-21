import java.util.*;
import java.io.*;

public class Array
{
    
    
    public static void main(String [] args) throws Exception
    {
        Reader r = new FileReader(args[0]);
        BufferedReader br = new BufferedReader(r);        
        List codeOrg = new ArrayList();        
        while(true) {
            String g = br.readLine();
            if(g==null) break;     
            Line aa = new Line(g);            
            codeOrg.add(aa);
        }      
        br.close();
        
        BlendConfig.initFlowConfig(null);
        
        Processor.main(codeOrg);
        main(codeOrg);    
        
        // Store the processed code in the output file
        OutputStream os = new FileOutputStream(args[1]);
        PrintStream ps = new PrintStream(os);
        Line.linesToStream(codeOrg,ps);               
        ps.flush();
        ps.close();
    }
            
    public static void main(List code) throws Exception
    {
        
        
        
    }
    
}

