
WITH Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS address,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Info AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Benchmark AS (
    SELECT 
        ci.c_customer_sk,
        ci.full_name,
        ci.cd_gender AS gender,
        si.total_spent,
        si.total_orders,
        CASE 
            WHEN si.total_spent IS NULL THEN 'No Purchases'
            WHEN si.total_spent < 100 THEN 'Low Spender'
            WHEN si.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
            ELSE 'High Spender'
        END AS spending_category
    FROM 
        Customer_Info ci
    LEFT JOIN 
        Sales_Info si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    spending_category,
    COALESCE(total_spent, 0) AS total_spent,
    COALESCE(total_orders, 0) AS total_orders
FROM 
    Benchmark
ORDER BY 
    spending_category DESC, total_spent DESC;
