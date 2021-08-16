import UIKit

class TherapyQuestionViewController: UIViewController {
    
    let label = UILabel()
    let button = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(label)
        view.addSubview(button)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.text = "Close Me"
        button.titleLabel?.textColor = .systemRed
        button.backgroundColor = .white
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 16),
            button.widthAnchor.constraint(equalTo: button.heightAnchor, multiplier: 2.0, constant: 60)
        ])
    }
    
    @objc private func onTap() {
        navigationController?.popViewController(animated: true)
    }
    
    func configure(with labelText: String) {
        label.text = labelText
    }
}
