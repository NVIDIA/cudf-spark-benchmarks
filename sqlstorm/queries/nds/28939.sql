
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
),
CustomerFullName AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        CASE
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        c_current_addr_sk
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cf.full_name,
    cf.cd_gender,
    cf.marital_status,
    ap.full_address,
    ap.ca_city,
    ap.ca_state,
    ap.ca_zip,
    ss.total_net_profit,
    ss.total_orders
FROM 
    CustomerFullName cf
JOIN 
    SalesSummary ss ON cf.c_customer_sk = ss.ws_bill_customer_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = cf.c_current_addr_sk
JOIN 
    AddressParts ap ON ap.ca_address_sk = ca.ca_address_sk
WHERE 
    ss.total_net_profit > 5000
ORDER BY 
    ss.total_net_profit DESC, cf.full_name;
