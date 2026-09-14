from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

def run_pipeline():
    print("Generating synthetic data for {{PROJECT_NAME}}...")
    X, y = make_classification(n_samples=1000, n_features=20, random_state=42)
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

    clf = RandomForestClassifier(n_estimators=50)
    clf.fit(X_train, y_train)

    preds = clf.predict(X_test)
    print(f"Model Accuracy: {accuracy_score(y_test, preds):.4f}")

if __name__ == "__main__":
    run_pipeline()
