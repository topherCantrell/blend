
import java.io.*;
import java.util.*;

public class Line
{
    
    String raw;    
    String rawNoComment;
    String label;
    String assem;
    String comment;
    String assemOpcode;
    String assemOperand;    
        
    boolean labelColon; // Sometimes labels have colons, sometimes they don't!
    
    // 1 = FLOW break statement
    // 2 = FLOW continue statement
    // 3 = FLOW jump statement (data = String:destination)
    // 4 = FLOW label (data = String:label)
    // 5 = FLOW branch statement (not a jump, data= String:destination)
    
    // Note the assumption ... a line can have only ONE special meaning.
    // For instance, it can't be a FLOW label with assembly that contains
    // a FLOW jump statement. The FLOW process ALWAYS puts FLOW labels on
    // a separate line, so this is not a problem.
    
    int specialType; 
    Object specialData;
    
    public void commentOutWholeLine()
    {           
        parse("; "+raw);
        specialData = null;
        specialType = 0;
    }
    
    public void appendComment(String ac)
    {
        if(comment!=null) {
            ac = comment+" "+ac;
        }
        comment = ac;
    }
    
    public void prependComment(String pc)
    {
        if(comment!=null) {
            pc = pc+" "+comment;
        }
        comment = pc;
    }
    
    public void changeAssem(String newAssem)
    {
        if(newAssem==null) {
            assem = null;
            assemOpcode = null;
            assemOperand = null;
            return;
        }
        
        assem = newAssem;
        int i = assem.indexOf(" ");
        if(i<0) {
            assemOpcode = newAssem;
            assemOperand = "";
        } else {
            assemOpcode = newAssem.substring(0,i);
            assemOperand = newAssem.substring(i+1).trim();
        }
    }
    
    public static String stripWhiteSpace(String s)
    {        
        byte [] b = s.getBytes();
        byte [] bb = new byte[b.length];
        int y = 0;
        for(int x=0;x<b.length;++x) {
            if(b[x]!=' ') {
                bb[y++] = b[x];
            }
        }
        return new String(bb,0,y);
    }
    
    public static void linesToStream(List code, PrintStream ps)
    {
        
        for(int x=0;x<code.size();++x) {
            Line a = (Line)code.get(x);             
            String lab = "";   if(a.label!=null)        lab=a.label;
            String asOp = "";  if(a.assemOpcode!=null)  asOp=a.assemOpcode;
            String asOr = "";  if(a.assemOperand!=null) asOr=a.assemOperand;
            String com = "";   if(a.comment!=null)      com = a.comment;
            if(com.length()>0) com="; "+com;
            if(a.labelColon) lab=lab+":";
            
            while(lab.length()<16) lab=lab+" ";
            while(asOp.length()<8) asOp=asOp+" ";
            while(asOr.length()<16) asOr=asOr+" ";
            
            ps.print(lab+" "+asOp+" "+asOr+" "+com);
            ps.print("\r\n"); 
            
        }
    }
    
    public Line(String raw)
    {
        parse(raw);
    }
    
    public void parse(String ss)
    {        
        this.raw = ss;
        
        label = null;
        assem = null;
        comment = null;
        assemOpcode = null;
        assemOperand = null;
        labelColon = false;
        
        while(true) {
            int x= ss.indexOf('\t');
            if(x<0) break;
            String tt = ss.substring(0,x)+"    "+ss.substring(x+1);
            ss = tt;
        }
        raw = ss;
        
        int i = ss.indexOf(";");
        if(i>=0) {
            comment = ss.substring(i+1);
            ss = ss.substring(0,i);
        }
                
        rawNoComment = ss;
                
        if(ss.length()>0 && !ss.startsWith(" ")) {    
            i = ss.indexOf(":");
            int j = i+1;
            if(i<0) {
                i = ss.indexOf(" ");
                j = i;
            }
            if(i<0) {
                j = ss.length();                
            }
            
            label = ss.substring(0,j);            
            ss = ss.substring(j);   
                        
            if(label.endsWith(":")) {
                labelColon = true;
                label = label.substring(0,label.length()-1);
            }            
        }       
        
        ss=ss.trim();
        if(ss.length()>0) {
            changeAssem(ss);            
        }        
       
    }
    
}
