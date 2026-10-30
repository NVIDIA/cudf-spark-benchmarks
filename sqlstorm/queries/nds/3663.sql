
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_date AS last_purchase_date,
        RANK() OVER (PARTITION BY cd_gender ORDER BY d.d_date DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_date >= '2023-01-01'
),
customer_totals AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ct.total_spent,
        ct.total_orders
    FROM 
        ranked_customers rc
    JOIN 
        customer_totals ct ON rc.c_customer_sk = ct.c_customer_sk
    WHERE 
        rc.purchase_rank <= 5
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_spent, 0) AS total_spent,
    COALESCE(tc.total_orders, 0) AS total_orders,
    CASE 
        WHEN tc.total_spent IS NULL THEN 'No Purchases'
        WHEN tc.total_spent < 100 THEN 'Low Spender'
        WHEN tc.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM
    top_customers tc
LEFT JOIN 
    customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL
ORDER BY 
    total_spent DESC;
