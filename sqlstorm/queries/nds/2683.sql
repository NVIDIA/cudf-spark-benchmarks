
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) AS avg_spent_per_order
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_orders,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rnk
    FROM 
        customer_stats cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_orders > 0
), 
latest_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_orders,
    tc.total_spent,
    COALESCE(lr.total_return_amount, 0) AS total_return_amount,
    (tc.total_spent - COALESCE(lr.total_return_amount, 0)) AS net_spent
FROM 
    top_customers tc
LEFT JOIN 
    latest_returns lr ON tc.c_customer_sk = lr.sr_customer_sk
WHERE 
    tc.rnk <= 10
ORDER BY 
    net_spent DESC;
