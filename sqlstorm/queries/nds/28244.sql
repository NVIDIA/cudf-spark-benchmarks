WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_county) AS county_upper,
        ca_state
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_bill_customer_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_bill_customer_sk
)
SELECT 
    a.full_address,
    a.city_lower,
    a.county_upper,
    a.ca_state,
    c.full_name,
    c.cd_gender,
    c.cd_marital_status,
    s.total_quantity,
    s.total_profit
FROM 
    AddressInfo a
JOIN 
    CustomerInfo c ON a.ca_address_sk = c.c_customer_sk   
JOIN 
    SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'NY' 
    AND s.total_profit > 1000
ORDER BY 
    s.total_profit DESC
LIMIT 10;