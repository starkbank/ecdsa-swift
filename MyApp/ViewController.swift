//
//  ViewController.swift
//  MyApp
//
//  Created by Rafael Stark on 2/14/21.
//  Copyright © 2021 Stark Bank. All rights reserved.
//

import BigInt
import starkbank
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let message = "Rafael"
        let privateKey = PrivateKey(secret: BigInt(2))
        let publicKey = privateKey.publicKey()
        
//        let baseEncoded = Base64.encode(string: String(privateKey.secret))
//        let baseDecoded: String = Base64.decode(string: baseEncoded)
        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        let isValid = Ecdsa.verify(message: message, signature: signature, publicKey: publicKey)

        self.textView.text = " r:\(signature.r)\n\n s:\(signature.s)\n\n v:\(isValid)"
    }
}

