
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.total_orders, 0) AS total_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData sd ON ci.c_customer_sk = sd.customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    c_email_address,
    ca_city,
    ca_state,
    ca_country,
    total_spent,
    total_orders,
    CASE 
        WHEN total_spent = 0 THEN 'No Purchases'
        WHEN total_spent < 500 THEN 'Low Spender'
        WHEN total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    CombinedData
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_spent DESC
LIMIT 100;
