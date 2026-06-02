window.downloadFileFromBytes = (filename, bytesBase64) => {
    var link = document.createElement('a');
    link.download = filename;
    link.href = 'data:application/octet-stream;base64,' + btoa(String.fromCharCode.apply(null, bytesBase64));
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
};