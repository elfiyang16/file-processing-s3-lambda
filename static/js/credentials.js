/**
 *  Retrieves creds created by the sts create session method in credentials lambda and uses it for multi-part s3 upload.
 *  Note the SDK has to be enabled as multi-part does not allow presign
 */

const credentialsUpload = (function () {
  const rootUrl = window.location.href.replace(/[^/]*$/, "");
  const queryUrl = rootUrl + "api/credentials";

  async function requestCredentials(selectedFile) {
    console.info("Requesting credentials for " + selectedFile.name);
    const request = {
      method: "POST",
      cache: "no-cache",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        key: selectedFile.name,
      }),
    };
    const response = await fetch(queryUrl, request);
    if (response.ok) {
      return response.json();
    } else {
      console.error("Failed to retrieve credentials: " + response.status);
    }
  }

  async function uploadFile(
    selectedFile,
    accessKeyId,
    secretAccessKey,
    sessionToken,
    region,
    bucket
  ) {
    AWS.config.region = region;
    AWS.config.credentials = new AWS.Credentials(
      accessKeyId,
      secretAccessKey,
      sessionToken
    );
    const s3 = new AWS.S3();

    console.info("Uploading " + selectedFile.name);
    const params = {
      Bucket: bucket,
      Key: selectedFile.name,
      ContentType: selectedFile.type,
      Body: selectedFile,
    };
    //  use of SDK
    const upload = new AWS.S3.ManagedUpload({ params: params });
    upload.on("httpUploadProgress", function (evt) {
      console.log(
        "uploaded " +
          evt.loaded +
          " of " +
          evt.total +
          " bytes for " +
          selectedFile.name
      );
    });
    return upload.promise();
  }

  return async function () {
    const selectedFile = document.getElementById("fileselector").files[0];
    if (typeof selectedFile == "undefined") {
      alert("Choose a file");
      return;
    }
    const creds = await requestCredentials(selectedFile);
    if (creds) {
      await uploadFile(
        selectedFile,
        creds.access_key,
        creds.secret_key,
        creds.session_token,
        creds.region,
        creds.bucket
      );
      alert("Upload via restricted credentials completed");
    }
  };
})();
