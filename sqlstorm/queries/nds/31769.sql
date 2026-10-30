
WITH  daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_date ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        d.d_date
),
customer_rankings AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(ws.ws_order_number) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ds.d_date,
    ds.total_sales,
    ds.total_orders,
    cr.c_first_name,
    cr.c_last_name,
    cr.cd_gender,
    cr.cd_marital_status
FROM 
    daily_sales ds
JOIN 
    customer_rankings cr ON ds.sales_rank = 1
WHERE 
    ds.total_sales > (
        SELECT AVG(total_sales) 
        FROM daily_sales 
        WHERE sales_rank <= 10
    )
ORDER BY 
    ds.total_sales DESC
LIMIT 10;
