public class NonRootUser {
    public static void main(String[] args) {
        String expectedUser = "app";
        String user = System.getProperty("user.name");
        assert user != null : "user.name is null";
        assert expectedUser != null : "expectedUser is null";
        assert expectedUser.equals(user) : "user.name is not '" + expectedUser + "'";
        System.out.println("SUCCESS: User is " + user);
    }
}
