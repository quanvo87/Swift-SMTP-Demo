import Kitura
import SwiftSMTP
import HeliumLogger
import LoggerAPI

// MARK: - SMTP
// The SMTP server you are going to connect to
let hostname = ""

// The email you will be sending from
let email = ""

// The password to the email
let password = ""

// Our SSL certificate files are in the same folder as `main.swift`. We are just
// grabbing the path here to reference them later.
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
let ssl = SSL(withCACertificateDirectory: nil,
              usingCertificateFile: cert,
              withKeyFile: key)
#else
let cert = root + "/cert.pfx"
let certPassword = "kitura"
let ssl = SSL(withChainFilePath: cert,
              withPassword: certPassword)
#endif

// The handle to the SMTP server with your login info
let smtp = SMTP(hostname: hostname,
                email: email,
                password: password,
                ssl: ssl)

// The `User` object that will act as our sender
let sender = User(name: "Swift-SMTP Demo",
                  email: email)

// MARK: - Kitura HTTP Server
HeliumLogger.use()

let router = Router()

// Serve our static index.html
router.all("/", middleware: StaticFileServer())

// Send an email on this route
router.get("/send/:email") { req, res, _ in

    // Get the email from the parameters
    let email = req.parameters["email"] ?? ""

    // Create a `User` object that will act as our receiver
    let receiver = User(email: email)

    // Create the `Mail` object that will be sent
    let mail = Mail(from: sender,
                    to: [receiver],
                    subject: "Swift-SMTP Test Email",
                    text: "Hello, world!")

    // Send the mail object
    smtp.send(mail, completion: { (error) in
        var message: String

        // Set the appropriate response message
        if let error = error {
            message = "Send failed: " + String(describing: error)
        } else {
            message = "Email successfully sent! You should see it in your sent box."
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
