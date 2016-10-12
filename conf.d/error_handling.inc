error_page 404 @not_found;
error_page 500 @internal_server_error;
error_page 502 @bad_gateway;
error_page 504 @gateway_timeout;

location @not_found {
    default_type text/html;
    return 404 '<html><body>Not found</body></html>';
}
location @internal_server_error {
    default_type text/html;
    return 500 '<html><body>Internal server error</body></html>';
}
location @bad_gateway {
    default_type text/html;
    return 502 '<html><body>Bad gateway</body></html>';
}
location @gateway_timeout {
    default_type text/html;
    return 504 '<html><body>Gateway timeout</body></html>';
}
