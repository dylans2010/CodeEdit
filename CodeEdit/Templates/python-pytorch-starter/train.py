import torch
from model import SimpleClassifier

def train():
    print("Training {{PROJECT_NAME}} classifier...")
    model = SimpleClassifier()
    x = torch.randn(16, 10)
    out = model(x)
    print("Output shape:", out.shape)

if __name__ == "__main__":
    train()
