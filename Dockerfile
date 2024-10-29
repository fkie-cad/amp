FROM python:3.11-bookworm

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/honeypots

COPY requirements.txt .

# https://pythonspeed.com/articles/faster-pip-installs/
RUN pip3 install \
  --disable-pip-version-check \
  --no-cache-dir \
  -r requirements.txt

USER nobody

CMD [ \
    "honeypots", \
    "--config", \
    "config.json", \
    "--setup", \
    "dhcp,dicom,dns,ftp,hl7,http,httpproxy,https,imap,ipp,ldap,mssql,mysql,ntp,oracle,pjl,pop3,rdp,sip,smb,smtp,snmp,ssh,telnet", \
    "--termination-strategy", \
    "signal" \
]
