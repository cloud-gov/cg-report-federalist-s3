#!/bin/bash
set -eu
SCREENSHOT=""
file_upload="body.txt"

# add an image to data.txt :
# $1 : type (ex : image/png)
# $2 : image content id filename (match the cid:filename.png in html document)
# $3 : image content base64 encoded
# $4 : filename for the attached file if content id filename empty
function add_file {
    echo "--MULTIPART-MIXED-BOUNDARY
Content-Type: $1
Content-Transfer-Encoding: base64" >> "$file_upload"

    if [ ! -z "$2" ]; then
        echo "Content-Disposition: inline
Content-Id: <$2>" >> "$file_upload"
    else
        echo "Content-Disposition: attachment; filename=$4" >> "$file_upload"
    fi
    echo "$3

" >> "$file_upload"
}

# html message to send
echo "<html>
<body>
    <div>
        <p>Please see the screenshot included below. Convert timestamps using a tool like <a href='https://www.epochconverter.com/'>epochconverter.com</a></p>
        <p>     -- the cloud.gov team</p>
        <p><img src=\"cid:cloudtrail-federalist.png\"></p>
    </div>
</body>
</html>" > message.html
message_base64=$(base64 message.html)

echo "From: $MAIL_FROM
To: $MAIL_TO
Subject: Federalist S3 CloudTrail - cloud.gov
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=\"MULTIPART-MIXED-BOUNDARY\"

--MULTIPART-MIXED-BOUNDARY
Content-Type: multipart/alternative; boundary=\"MULTIPART-ALTERNATIVE-BOUNDARY\"

--MULTIPART-ALTERNATIVE-BOUNDARY
Content-Type: text/html; charset=utf-8
Content-Transfer-Encoding: base64
Content-Disposition: inline

$message_base64
--MULTIPART-ALTERNATIVE-BOUNDARY--" > "$file_upload"

# add an image with corresponding content-id
report_file="gif-recording/federalist-report.gif"
echo $(file $report_file)
gif_content=$(base64 $report_file)
add_file "image/png" "cloudtrail-federalist.png" "${gif_content}"

# end of uploaded file
echo "--MULTIPART-MIXED-BOUNDARY--" >> "$file_upload"

# send email
echo "sending ...."
curl -s "smtp://${SMTP_HOST}" \
     --mail-from "${MAIL_FROM}" \
     --mail-rcpt "${MAIL_TO}" \
     --ssl -u "${SMTP_USER}:${SMTP_PASS}" \
     -T "$file_upload" -k --anyauth
res=$?
if test "$res" != "0"; then
  echo "sending failed with: $res"
  exit 1
else
  echo "OK"
fi
