import java.net.URL;
import javax.net.ssl.HttpsURLConnection;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class TestSSL {
    public static void main(String[] args) {
        System.setProperty("javax.net.debug", "ssl:handshake:verbose");
        System.setProperty("javax.net.ssl.trustStore", System.getProperty("user.home") + "/.speedscale/certs/cacerts.jks");
        System.setProperty("javax.net.ssl.trustStorePassword", "changeit");
        
        try {
            URL url = new URL("https://localhost:65081/api/models");
            HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            
            int responseCode = conn.getResponseCode();
            System.out.println("Response Code: " + responseCode);
            
            BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
            reader.close();
            
        } catch (Exception e) {
            System.err.println("SSL Test Failed: " + e.getMessage());
            e.printStackTrace();
        }
    }
}