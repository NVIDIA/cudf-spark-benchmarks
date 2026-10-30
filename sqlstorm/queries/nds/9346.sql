
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        CAST(d.d_date AS DATE) AS sale_date,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws_bill_customer_sk, d.d_date
),
customer_stats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ss.total_sales) AS total_sales,
        COUNT(ss.order_count) AS total_orders
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary ss ON cd.cd_demo_sk = ss.customer_id
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    cs.cd_demo_sk,
    cs.cd_gender,
    cs.total_sales,
    cs.total_orders,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Spender'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    customer_stats cs
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
