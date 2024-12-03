provider_credentials = {
    subscription_id  = "{tmp_subscription_id}"
    tenant_id        = "{tmp_tenant_id}"
    sp_client_id     = "{tmp_sp_client_id}"
    sp_client_secret = "{tmp_sp_client_secret}"
}

resource_group_config = {
    name             = "{tmp_resource_group_name}"
    location         = "{tmp_resource_group_location}"
}

db_server_config={
    name             = "{tmp_db_server_name}"
    user             = "{tmp_db_server_user}"
    password         = "{tmp_db_server_password}"
}

db_config={
    name             = "{tmp_db_name}"  
}

app_config={
    name             = "{tmp_app_name}"  
}

servicebus_config={
    name             = "{tmp_servicebus_name}"  
}

storage_account_config={
    name             = "{tmp_storage_account_name}"  
}

function_config={
    name             = "{tmp_function_name}"  
}
