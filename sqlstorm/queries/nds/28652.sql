
WITH ProcessedAddresses AS (
    SELECT 
        REPLACE(UPPER(ca_street_name), 'STREET', 'ST') AS processed_street_name,
        ca_city,
        ca_zip,
        ca_state,
        ca_address_sk
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_zip IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        pa.processed_street_name,
        pa.ca_city,
        pa.ca_state,
        pa.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ProcessedAddresses pa ON c.c_current_addr_sk = pa.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid,
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.c_email_address
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    SUM(sd.ws_net_paid) AS total_spent,
    COUNT(DISTINCT sd.ws_order_number) AS order_count
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.c_customer_sk
GROUP BY 
    cd.c_first_name, cd.c_last_name, cd.c_email_address
HAVING 
    SUM(sd.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC;
