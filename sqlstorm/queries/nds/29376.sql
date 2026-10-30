
WITH AddressConcat AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
            COALESCE(CONCAT(' Suite ', ca_suite_number), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerFullName AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cf.full_name,
    cf.cd_gender,
    cf.cd_marital_status,
    cf.cd_education_status,
    ac.full_address,
    sd.total_profit,
    sd.order_count,
    sd.total_quantity
FROM 
    CustomerFullName cf
LEFT JOIN 
    AddressConcat ac ON cf.c_customer_sk = ac.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cf.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    LENGTH(cf.full_name) > 15 AND
    sd.total_profit > 1000
ORDER BY 
    sd.total_profit DESC
LIMIT 50;
