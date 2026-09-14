import UIKit

class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton(type: .system)
        button.setTitle("CodeEdit Key", for: .normal)
        button.addTarget(self, action: #selector(didTapKey), for: .touchUpInside)
        view.addSubview(button)
        button.frame = CGRect(x: 20, y: 20, width: 140, height: 44)
    }

    @objc func didTapKey() {
        textDocumentProxy.insertText("{{PROJECT_NAME}} ")
    }
}
