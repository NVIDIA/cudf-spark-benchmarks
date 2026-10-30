WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit,
        COUNT(DISTINCT ws_web_page_sk) AS unique_web_pages
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450110 AND 2450175 
    GROUP BY ws_bill_customer_sk
),

customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sales.total_sales,
        sales.order_count,
        sales.avg_profit,
        sales.unique_web_pages
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_summary sales ON c.c_customer_sk = sales.ws_bill_customer_sk
),

ranked_customers AS (
    SELECT 
        cs.*,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        RANK() OVER (ORDER BY cs.avg_profit DESC) AS profit_rank
    FROM customer_summary cs
)

SELECT 
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.total_sales,
    r.order_count,
    r.avg_profit,
    r.unique_web_pages,
    r.sales_rank,
    r.profit_rank
FROM ranked_customers r
WHERE r.total_sales IS NOT NULL
ORDER BY r.sales_rank, r.profit_rank
LIMIT 100;