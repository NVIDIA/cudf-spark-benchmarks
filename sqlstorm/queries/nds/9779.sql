
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_web_page_sk) AS unique_pages_viewed
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders,
        COALESCE(s.avg_net_profit, 0) AS avg_net_profit,
        COALESCE(s.unique_pages_viewed, 0) AS unique_pages_viewed
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
),
sales_ranked AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_details
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.total_sales,
    c.total_orders,
    c.avg_net_profit,
    c.unique_pages_viewed,
    c.sales_rank
FROM 
    sales_ranked c
WHERE 
    c.sales_rank <= 10
ORDER BY 
    c.total_sales DESC;
