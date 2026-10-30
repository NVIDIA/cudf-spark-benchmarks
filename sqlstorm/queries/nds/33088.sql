
WITH  sales_trends AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_date_id
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(ws.ws_net_paid) AS total_purchases
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender
    ORDER BY 
        total_purchases DESC
    LIMIT 100
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    AVG(ws.ws_net_paid) AS avg_spent,
    tc.total_purchases,
    CASE 
        WHEN tc.total_purchases IS NULL THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_status
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    top_customers tc ON c.c_customer_sk = tc.c_customer_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, tc.total_purchases
ORDER BY 
    total_quantity_sold DESC, avg_spent DESC;
