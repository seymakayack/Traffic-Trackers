import UIKit

class CustomSegue: UIStoryboardSegue {
    override func perform() {
        let sourceVC = self.source
        let destinationVC = self.destination

        guard let window = sourceVC.view.window else {
            sourceVC.present(destinationVC, animated: false, completion: nil)
            return
        }

        // Set the initial position of the destination view
        destinationVC.view.frame = window.bounds
        destinationVC.view.transform = CGAffineTransform(translationX: window.frame.width, y: 0)

        // Add the destination view to the window
        window.addSubview(destinationVC.view)

        // Perform the animation
        UIView.animate(withDuration: 0.5, animations: {
            destinationVC.view.transform = .identity
        }) { _ in
            window.rootViewController = destinationVC
        }
    }
}
