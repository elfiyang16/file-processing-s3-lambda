/**
 *  This code retrieves a pre-signed url from the presign lambda(constructued with signature  v4 ) and uses it to upload a file.
 */

const signedUrlUpload = (function () {
  const rootUrl = window.location.href.replace(/[^/]*$/, "");
  const queryUrl = rootUrl + "api/presign";

  async function requestSignedUrl(selectedFile) {
    console.log("requesting URL for " + selectedFile.name);
    const request = {
      method: "POST",
      cache: "no-cache",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key: selectedFile.name,
        type: selectedFile.type,
      }),
    };
    const response = await fetch(queryUrl, request);
    if (response.ok) {
      content = await response.json();
      return content.url;
    } else {
      console.error("Failed to retrieve signed URL: " + response.status);
    }
  }

  async function loadFileContent(selectedFile) {
    console.info("Retrieving content for " + selectedFile.name);
    return new Promise(function (resolve, reject) {
      const reader = new FileReader();
      reader.onload = (e) => resolve(e.target.result);
      reader.onabort = reject;
      //   reader.readAsArrayBuffer(selectedFile);
      reader.readAsBinaryString(selectedFile);
    });
  }

  async function uploadFile(selectedFile, content, url) {
    console.info("Uploading " + selectedFile.name);
    const request = {
      method: "PUT",
      mode: "cors",
      cache: "no-cache",
      headers: {
        "Content-Type": selectedFile.type,
      },
      body: content,
    };
    const response = await fetch(url, request);
    console.info("Upload status: " + response.status);
  }

  return async function () {
    const selectedFile = document.getElementById("fileselector").files[0];
    if (typeof selectedFile == "undefined") {
      alert("Choose a file");
      return;
    }

    const url = await requestSignedUrl(selectedFile);
    const content = await loadFileContent(selectedFile);
    if (url && content) {
      await uploadFile(selectedFile, content, url);
      alert("Upload via signed URL completed");
    }
  };
})();
