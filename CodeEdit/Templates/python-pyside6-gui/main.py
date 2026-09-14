import sys
from PySide6.QtWidgets import QApplication, QLabel, QMainWindow

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("{{PROJECT_NAME}}")
        self.setCentralWidget(QLabel("Hello from {{PROJECT_NAME}} in PySide6!"))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.resize(400, 250)
    window.show()
    sys.exit(app.exec())
