
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_education_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(sd.total_orders, 0) AS total_orders
FROM 
    CustomerDetails cu
JOIN 
    customer_address ca ON cu.c_customer_sk = ca.ca_address_sk
JOIN 
    AddressDetails ad ON ca.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON cu.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    ad.ca_state = 'CA' AND 
    cu.cd_marital_status = 'M'
ORDER BY 
    total_net_profit DESC, 
    cu.full_name ASC
LIMIT 100;
