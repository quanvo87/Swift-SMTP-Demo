import Kitura
import SwiftSMTP
import HeliumLogger
import LoggerAPI

// MARK: - SMTP
// The SMTP server you are going to connect to
let hostname = "smtp.gmail.com"

// The email you will be sending from
let email = "kiturasmtp@gmail.com"

// The password to the email
let password = "ibm12345"

let root = #file
    .characters
    .split(separator: "/", omittingEmptySubsequences: false)
    .dropLast(1)
    .map { String($0) }
    .joined(separator: "/")

// Init an SSL instance depending on OS
#if os(Linux)
let cert = root + "/cert.pem"
let key = root + "/key.pem"
let ssl = SSL(withCACertificateDirectory: nil, usingCertificateFile: cert, withKeyFile: key)
#else
let cert = root + "/cert.pfx"
let certPassword = "kitura"
let ssl = SSL(withChainFilePath: cert, withPassword: certPassword)
#endif

// The handle to the SMTP server with your login info
let smtp = SMTP(hostname: hostname, user: email, password: password, ssl: ssl)

// The `User` object that will act as our sender
let sender = User(name: "Swift-SMTP Tester", email: email)

// MARK: - Kitura
HeliumLogger.use()

let router = Router()

// Serve our static index.html
router.all("/", middleware: StaticFileServer())

// Send an email to the given parameter
router.get("/send/:email") { req, res, _ in

    // Get the email
    let email = req.parameters["email"] ?? ""

    // Create a `User` object that will act as our receiver
    let receiver = User(email: email)

    // Create the `Mail` object that will be sent
    let mail = Mail(from: sender, to: [receiver], subject: "Swift-SMTP Test", text: "Hello, world!")

    // Send the mail object
    smtp.send(mail, completion: { (error) in
        var message: String

        // Set the appropriate response message
        if let error = error {
            message = "Send failed: " + String(describing: error)
        } else {
            message = "Email successfully sent! Try checking your email now."
        }

        // Send the response
        do {
            try res.send(message).end()
        } catch {
            Log.error("\(error)")
        }
    })
}

Kitura.addHTTPServer(onPort: 8080, with: router)
Kitura.run()
