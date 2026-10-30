
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        LOWER(ca_city) AS city,
        LOWER(ca_state) AS state
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesAggregates AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MAX(ws.ws_sales_price) AS max_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.full_address,
    cu.full_name,
    cu.cd_gender,
    cu.cd_marital_status,
    sa.total_orders,
    sa.total_spent,
    sa.avg_order_value,
    sa.max_order_value
FROM 
    AddressParts ca
JOIN 
    CustomerDetails cu ON ca.ca_address_sk = cu.c_customer_sk
LEFT JOIN 
    SalesAggregates sa ON cu.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    ca.city IN ('new york', 'los angeles')
ORDER BY 
    sa.total_spent DESC
LIMIT 100;
