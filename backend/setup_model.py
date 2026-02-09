import os
import requests
import zipfile
import shutil

# 1. Configuration
MODEL_URL = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
ZIP_NAME = "model.zip"
EXTRACTED_FOLDER_NAME = "vosk-model-small-en-us-0.15"
FINAL_FOLDER_NAME = "model"

def download_and_setup():
    # Check if model already exists
    if os.path.exists(FINAL_FOLDER_NAME):
        print(f"✅ Model folder '{FINAL_FOLDER_NAME}' already exists! Skipping download.")
        return

    print(f"⬇️  Downloading AI Model (approx 40MB)... please wait.")
    
    # 2. Download the file
    try:
        response = requests.get(MODEL_URL, stream=True)
        with open(ZIP_NAME, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print("✅ Download complete.")

        # 3. Unzip the file
        print("Pg  Unzipping...")
        with zipfile.ZipFile(ZIP_NAME, 'r') as zip_ref:
            zip_ref.extractall(".")
        
        # 4. Rename folder to 'model'
        print("Pg  Configuring...")
        if os.path.exists(EXTRACTED_FOLDER_NAME):
            os.rename(EXTRACTED_FOLDER_NAME, FINAL_FOLDER_NAME)
        
        # 5. Cleanup (Delete the zip file)
        os.remove(ZIP_NAME)
        print(f"🎉 Success! The AI Brain is ready in folder: '{FINAL_FOLDER_NAME}'")

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    download_and_setup()