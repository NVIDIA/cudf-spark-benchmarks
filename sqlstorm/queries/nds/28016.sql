
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY') 
        AND ca_city IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails AS ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.full_address,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    CustomerInfo AS ci
LEFT JOIN 
    SalesData AS sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_spent DESC, 
    ci.c_last_name, 
    ci.c_first_name
LIMIT 100;
