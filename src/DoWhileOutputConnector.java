
import java.util.*;

/**
 * This OutputConnector's toString method implements the logic flow
 * for a do-while loop.
 */
public class DoWhileOutputConnector extends OutputConnector
{
    
     public DoWhileOutputConnector(String name,SpecialConstructInfo info)
     {
         super(name,info);
     }
    
     public void toAssembly(List outlines) {         
         
         // BEGIN label         
         String label = name+"_BEGIN";
         Line a = new Line(label+":");            
         outlines.add(a);
         a.specialType = 4; a.specialData = label;
         
         // TRUE label
         label = name+"_TRUE";
         a = new Line(label+":");            
         outlines.add(a);
         a.specialType = 4; a.specialData = label;
         
         // TRUE block
         outlines.add(new Line("$TRUE"));
         
         // LOGIC block
         outlines.add(new Line("$LOGIC"));
         
         // FALSE label
         label = name+"_FALSE";
         a = new Line(label+":");            
         outlines.add(a);
         a.specialType = 4; a.specialData = label;
         
         // END label
         label = name+"_END";
         a = new Line(label+":");            
         outlines.add(a);
         a.specialType = 4; a.specialData = label;         
         
     }
     
}


