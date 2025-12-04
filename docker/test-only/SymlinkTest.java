import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class SymlinkTest {
    public static void main(String[] args) {
        Path symlinkPath = Paths.get("/app");
        Path expectedTarget = Paths.get("/home/app");
        
        try {
            // Check if /app exists
            assert Files.exists(symlinkPath) : "/app does not exist";
            
            // Check if /app is a symbolic link
            assert Files.isSymbolicLink(symlinkPath) : "/app is not a symbolic link";
            
            // Check if the symlink points to /home/app
            Path actualTarget = Files.readSymbolicLink(symlinkPath);
            assert actualTarget.equals(expectedTarget) : 
                "/app does not point to /home/app, it points to " + actualTarget;
            
            // Check if the target (/home/app) exists
            assert Files.exists(expectedTarget) : "/home/app does not exist";
            
            System.out.println("SUCCESS: /app symlink correctly points to /home/app");
        } catch (IOException e) {
            System.err.println("ERROR: " + e.getMessage());
            System.exit(1);
        } catch (AssertionError e) {
            System.err.println("ASSERTION FAILED: " + e.getMessage());
            System.exit(1);
        }
    }
}
