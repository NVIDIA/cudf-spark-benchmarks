
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value,
        COUNT(DISTINCT ws_web_page_sk) AS unique_web_pages_visited
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20221001 AND 20221031
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_rank AS (
    SELECT 
        customer_id,
        total_sales,
        order_count,
        avg_order_value,
        unique_web_pages_visited,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    ci.customer_id,
    ci.cd_gender,
    ci.marital_status,
    ci.hd_income_band_sk,
    sr.total_sales,
    sr.order_count,
    sr.avg_order_value,
    sr.unique_web_pages_visited,
    sr.sales_rank
FROM 
    customer_info ci
JOIN 
    sales_rank sr ON ci.customer_id = sr.customer_id
WHERE 
    sr.sales_rank <= 100
ORDER BY 
    sr.sales_rank;
