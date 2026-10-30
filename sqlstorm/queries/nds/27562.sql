
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year
),
CustomerBenchmark AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        ca_city,
        ca_state,
        ca_country,
        EXTRACT(YEAR FROM DATE '2002-10-01') - c_birth_year AS age,
        total_orders,
        total_spent,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM 
        CustomerInfo
)
SELECT 
    cb.full_name,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.ca_city,
    cb.ca_state,
    cb.ca_country,
    cb.age,
    cb.total_orders,
    cb.total_spent,
    cb.spend_rank,
    CASE 
        WHEN cb.spend_rank <= 10 THEN 'Top 10% Customers'
        WHEN cb.spend_rank <= 50 THEN 'Top 50% Customers'
        ELSE 'Others'
    END AS customer_segment
FROM 
    CustomerBenchmark cb
WHERE 
    cb.total_orders > 0
ORDER BY 
    cb.spend_rank
LIMIT 100;
