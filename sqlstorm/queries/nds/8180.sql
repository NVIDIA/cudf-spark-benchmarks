
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    d.cd_gender,
    dm.demographic_count
FROM 
    top_customers tc
JOIN 
    demographics d ON d.demographic_count = (SELECT MAX(demographic_count) FROM demographics) 
JOIN 
    demographics dm ON dm.cd_gender = d.cd_gender
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
