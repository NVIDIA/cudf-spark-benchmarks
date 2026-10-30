
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        cs.sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.sales_rank <= 10
)
SELECT 
    c.c_customer_id,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE((SELECT SUM(sr_return_amt) 
               FROM store_returns sr 
               WHERE sr.sr_customer_sk = c.c_customer_sk), 0) AS total_returns,
    CASE 
        WHEN COALESCE(cs.total_sales, 0) > 0 THEN 
             (COALESCE((SELECT SUM(sr_return_amt) 
                        FROM store_returns sr 
                        WHERE sr.sr_customer_sk = c.c_customer_sk), 0) / COALESCE(cs.total_sales, 1))
        ELSE 
            NULL 
    END AS return_rate 
FROM 
    customer c
LEFT JOIN 
    top_customers cs ON c.c_customer_id = cs.c_customer_id
ORDER BY 
    total_sales DESC;
