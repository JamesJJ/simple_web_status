#!/bin/bash

mkdir -p /var/www

F='/var/www/index.html'

[ ! -f /etc/curl_tests.txt ] && exit 1

IFS=$'\n'

TESTS=($(cat /etc/curl_tests.txt | egrep -v '^#'))

[ -z "${CURL_ARGS}" ] && CURL_ARGS='-A "ops-curl-check/1.0" --max-time 2 --retry 0 --tlsv1.2'
[ -z "${TITLE}" ] && TITLE='Health Status'

cat - <<EOF > "${F}.tmp"
<html>
  <head>
    <meta charset="UTF-8">
    <meta http-equiv="content-type" content="text/html;charset=utf-8" />
    <meta name="viewport" content="width=device-width" />
    <title>${TITLE}</title>

    <script type="text/javascript">
        setTimeout(function(){
          try {
            window.location = window.location.href = '?i=' + Math.floor(Date.now() / 100000)
          } catch(e) { }
        }, 60000);
    </script>
    
    <link rel="stylesheet"
       href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
       integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u"
       crossorigin="anonymous">

    <style type="text/css">
      *, *:before, *:after {
        -webkit-box-sizing: border-box;
        -moz-box-sizing: border-box;
        box-sizing: border-box;
      }
      @media all and (orientation:portrait){
        html {
          min-height: 100%;
        }
      }
      body {
        margin: 0 0 0 0;
        min-height: 100%;
        background: #80a0ff;
        background: linear-gradient(#fff, #ccc);
         -webkit-background-size: cover;
        -moz-background-size: cover;
        -o-background-size: cover;
        background-size: cover;
        font-family: 'lucida sans unicode', 'lucida grande', sans-serif;
        text-align: center;
        color: #000000;
      }
      h1 {
        font-size:2em;
        font-weight: normal;
        display: block;
        margin: 2em auto 1em auto;
      }
      p {
        font-size:1em;
        font-weight: normal;
        display: block;
        margin: 2em auto 1em auto;
      }
      .small {
        font-size: 0.75em;
      }
      td {
        font-size: 0.75em;
      }
      .vsmall {
        font-size: 0.65em;
      }
      table {
        font-family: Menlo, Monaco, Consolas, "Courier New", monospace;
      }
    </style>

  </head>
  <body>
    <h1>${TITLE}</h1>
    <p>$(date -u)</p>
    <table class="table table-responsive table-bordered table-condensed">
      <tr>
       <th>Result</th>
       <th>Name</th>
       <th>Desired</th>
       <th>Actual</th>
       <th>URL</th>
       <th class="col-md-4">Body (truncated to 200 characters)</th>
      </tr>
EOF

for TEST in "${TESTS[@]}"
do
  printf "" > /tmp/simple_check_body
  R='FAIL'
  CLASS='danger'
  T=($(echo "${TEST}" | awk  ' { split($0,a,","); print substr(a[1],0,32) "\n" a[2] "\n" a[3] } '))
  HTTP="$(curl ${CURL_ARGS} -s -o /tmp/simple_check_body -w "%{http_code}" "${T[2]}")"
  BODY="$(cat /tmp/simple_check_body | perl -C7 -0777 -n -Mutf8 -mHTML::Entities -e 'print HTML::Entities::encode_entities(substr(join("",$_),0,200)) ;')"
  # echo '============'
  # echo "${T[0]}"
  # echo "${T[1]}"
  # echo "${T[2]}"
  # echo "${HTTP}"
  # [ -f /tmp/simple_check_body ] && cat /tmp/simple_check_body | tr "\n" " " | cut -c 1-200
  if [ ${HTTP} -eq ${T[1]} ]
  then
    R='PASS'
    CLASS='success'
  fi
  echo "<tr class=\"${CLASS}\"><td>${R}</td><td>${T[0]}</td><td>${T[1]}</td><td>${HTTP}</td><td class=\"vsmall\">${T[2]}</td><td class=\"vsmall\">${BODY}</td><tr>" >> "${F}.tmp"
done

cat - <<EOF >> "${F}.tmp"
    </table>
  </body>
</html>
EOF

[ -f "${F}.tmp" ] && chmod 644 "${F}.tmp"
mv -f "${F}.tmp" "${F}"

