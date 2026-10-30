
WITH customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0)) AS total_purchases,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_purchases,
        cp.total_spent,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer_purchases cp
    JOIN 
        customer_demographics cd ON cp.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cp.total_spent > (SELECT AVG(total_spent) FROM customer_purchases)
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        hv.c_customer_sk,
        hv.c_first_name,
        hv.c_last_name,
        hv.total_purchases,
        hv.total_spent,
        hv.cd_marital_status,
        hv.cd_credit_rating
    FROM 
        high_value_customers hv
    JOIN 
        customer_address ca ON hv.c_customer_sk = ca.ca_address_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(a.c_customer_sk) AS customer_count,
    SUM(a.total_spent) AS total_revenue,
    AVG(a.total_spent) AS average_spent,
    COUNT(DISTINCT a.cd_credit_rating) AS unique_credit_ratings
FROM 
    customer_addresses a
GROUP BY 
    a.ca_city, a.ca_state
ORDER BY 
    total_revenue DESC
LIMIT 10;
