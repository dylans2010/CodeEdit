import requests
from bs4 import BeautifulSoup

def scrape():
    url = "https://example.com"
    print(f"Scraping {url} for {{PROJECT_NAME}}...")
    resp = requests.get(url)
    soup = BeautifulSoup(resp.text, "html.parser")
    title = soup.find("h1")
    print("Page Title:", title.text if title else "No title")

if __name__ == "__main__":
    scrape()
