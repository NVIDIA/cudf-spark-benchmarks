
WITH  sales_summary AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_order_number, ws_item_sk
    HAVING
        SUM(ws_ext_sales_price) > 100
),
customer_stats AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        COALESCE(SUM(ss.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(ss.total_sales), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_item_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
    HAVING 
        COALESCE(SUM(ss.total_sales), 0) > 500
),
date_filter AS (
    SELECT 
        d.d_date 
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
)
SELECT 
    c.c_customer_id,
    c_stats.total_quantity,
    c_stats.total_sales,
    d.d_date,
    CASE 
        WHEN c_stats.total_sales IS NULL OR c_stats.total_sales = 0 THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status
FROM 
    customer_stats c_stats
CROSS JOIN 
    date_filter d
LEFT JOIN 
    customer c ON c.c_customer_id = c_stats.c_customer_id
WHERE 
    (c_stats.total_quantity > 5 OR c_stats.total_sales IS NOT NULL)
ORDER BY 
    c_stats.total_sales DESC 
LIMIT 100;
