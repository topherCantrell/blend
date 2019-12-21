import java.util.*;

/**
 * This class houses the information for a special construct to expand.
 */
public class SpecialConstructInfo
{
    int type;           // 1=if/else 2=while 3=do-while
    String expression;  // The expression in the if/while parenthesis 
    String baseName;    // Unique baseName for this construct
        
    List normalBlock = new ArrayList();    // The lines of the normal block
    List elseBlock = new ArrayList();      // The lines of the else block (if any)    
   
}
