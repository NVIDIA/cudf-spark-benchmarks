WITH  sales_hierarchy AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
gender_sales AS (
    SELECT 
        sd.cd_gender,
        SUM(sh.total_sales) AS gender_total_sales,
        AVG(sh.order_count) AS avg_orders
    FROM 
        sales_hierarchy sh
        JOIN customer_demographics sd ON sh.customer_id = sd.cd_demo_sk
    WHERE 
        sh.rank = 1
    GROUP BY 
        sd.cd_gender
),
monthly_sales AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        SUM(ws.ws_ext_sales_price) AS total_monthly_sales
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    g.cd_gender,
    g.gender_total_sales,
    g.avg_orders,
    COALESCE(m.total_monthly_sales, 0) AS monthly_sales
FROM 
    gender_sales g
LEFT JOIN 
    monthly_sales m ON g.gender_total_sales = m.total_monthly_sales 
WHERE 
    g.gender_total_sales > (SELECT AVG(gender_total_sales) FROM gender_sales)
ORDER BY 
    g.gender_total_sales DESC
LIMIT 5;