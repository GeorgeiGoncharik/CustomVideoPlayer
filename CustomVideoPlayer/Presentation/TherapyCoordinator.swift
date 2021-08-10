import UIKit

class TherapyCoordinator {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        start()
    }
    
    func start() {
        let viewModel = VideoTherapyViewModel()
        viewModel.navigation = self
        let viewController = VideoTherapyViewController()
        viewController.configure(with: viewModel)
        navigationController.viewControllers = [viewController]
    }
}

extension TherapyCoordinator: VideoTherapyNavigation {
    func openQuestion(question: String) {
        let questionViewController = TherapyQuestionViewController()
        questionViewController.configure(with: question)
        navigationController.pushViewController(questionViewController, animated: true)
    }
    
    func finishTherapy() {
        print("VideoTherapyViewModel called finishTherapy() method. processing some logic here...")
    }
}
