#!/bin/bash

mkdir -p /var/www

F='/var/www/index.html'

[ ! -f /etc/curl_tests.txt ] && exit 1
echo > "${F}.PASS.tmp"
echo > "${F}.FAIL.tmp"
echo > "${F}.USER.tmp"

get_test_t() {
  local IFS=$'\n' 
  T=($(echo "${TEST}" | awk  ' { split($0,a,","); print substr(a[1],0,32) "\n" a[2] "\n" a[3] "\n" a[4] } '))
}

read_tests() {
  local IFS=$'\n' 
  TESTS=($(cat /etc/curl_tests.txt | egrep -v '^#'))
}
read_tests

[ -z "${CURL_ARGS}" ] && CURL_ARGS='-A ops-curl-check/1.0 --max-time 3 --retry 0 --tlsv1.2'
[ -z "${TITLE}" ] && TITLE='Health Status'
[ "${RESULT_SORT}" != "USER" ] && RESULT_SORT='RESULT'

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
  EXT='USER.tmp'
  get_test_t
  if [ -z "${T[3]}" ]
  then
    CURL_ARGS_GO="${CURL_ARGS}"
    HOST_HTML=""
  else
    CURL_ARGS_GO="${CURL_ARGS} -H Host:${T[3]}"
    HOST_HTML="<br>(${T[3]})"
  fi
  HTTP="$(curl ${CURL_ARGS_GO} -s -o /tmp/simple_check_body -w "%{http_code}" "${T[2]}")"
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
    [ "${RESULT_SORT}" = 'RESULT' ] && EXT='PASS.tmp'
  else
    R='FAIL'
    CLASS='danger'
    [ "${RESULT_SORT}" = 'RESULT' ] && EXT='FAIL.tmp'
  fi
  echo "<tr class=\"${CLASS}\"><td>${R}</td><td>${T[0]}</td><td>${T[1]}</td><td>${HTTP}</td><td class=\"vsmall\">${T[2]}${HOST_HTML}</td><td class=\"vsmall\">${BODY}</td><tr>" >> "${F}.${EXT}"
done

cat "${F}.USER.tmp" "${F}.FAIL.tmp" "${F}.PASS.tmp" - <<EOF >> "${F}.tmp"
    </table>
  </body>
</html>
EOF

[ -f "${F}.tmp" ] && chmod 644 "${F}.tmp"
mv -f "${F}.tmp" "${F}"

