import FirebaseAuth
import Combine
import FirebaseCrashlytics

class AuthManager: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var isRegisterMode: Bool = false
    

    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    
    func login() {
        let trimmedEmail = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Invalid email format."
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }
        
        Auth.auth().signIn(withEmail: trimmedEmail, password: trimmedPassword) { [weak self] result, error in
            print("Logging in with email: \(trimmedEmail), password: \(trimmedPassword)")
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoggedIn = false
                    ErrorLogger.log(error, additionalInfo: ["source": "AuthManager login"])  // change "login" to relevant function name
                } else {
                    self?.errorMessage = ""
                    self?.isLoggedIn = true
                }
            }
        }
    }
    
    func register() {
        let trimmedEmail = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Invalid email format."
            return
        }
        
        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }
        
        Auth.auth().createUser(withEmail: trimmedEmail, password: trimmedPassword) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoggedIn = false
                } else {
                    self?.errorMessage = ""
                    self?.isLoggedIn = true
                }
            }
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.username = ""
                self.password = ""
                self.errorMessage = ""
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
