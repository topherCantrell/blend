import java.io.*;
import java.util.*;

public class Blend {

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
        //System.out.println("BLEND: Number ... ");
        Number.main(code);          // Number the lines
        // Defines.main(code);      // Our own defines
        //System.out.println("BLEND: Subroutines ... ");
        Subroutines.main(code);     // Process subroutine calls
        
        //System.out.println("BLEND: Constants ... ");
        Constants.main(code);       // 0x, 0b, and 0o constants to decimal
        
        //System.out.println("BLEND: StructurewAndArrays ... ");
        Structures.main(code);      // Resolve structure access and arrays
        
        //System.out.println("BLEND: Data ... ");
        Data.main(code);            // Resolve data-definitions         
        
        //System.out.println("BLEND: Flow ... ");
        Flow.main(code);            // Process flow constructs (if, etc)        
        
        //System.out.println("BLEND: Substitutions ... ");
        Substitutions.main(code);   // Process direct substitutions
    }
}
