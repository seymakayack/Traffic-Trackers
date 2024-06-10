//
//  startPage.swift
//  TrafficTracker
//
//  Created by Seyma on 5.06.2024.
//

import UIKit

class startPage: UIViewController {

    @IBOutlet weak var startButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }


    
    @IBAction func startButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "transition", sender: self)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
