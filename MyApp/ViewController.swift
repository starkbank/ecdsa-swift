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
        print(privateKey.secret)
        
        print(publicKey.toPem())
        print("DER: \(publicKey.toDer())")
        let signature = Ecdsa.sign(message: message, privateKey: privateKey)
        self.textView.text = " r:\(signature.r)\n\n s:\(signature.s)"
    }
}

