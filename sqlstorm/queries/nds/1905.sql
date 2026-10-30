
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 1030
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        c.c_current_cdemo_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
filtered_sales AS (
    SELECT 
        w.ws_item_sk,
        w.ws_sales_price,
        w.ws_ext_sales_price,
        s.total_sales
    FROM 
        web_sales w
    JOIN 
        sales_summary s ON w.ws_item_sk = s.ws_item_sk
    WHERE 
        s.sales_rank <= 5
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.c_customer_sk,
    COALESCE(wp.wp_web_page_id, 'N/A') AS web_page_id,
    f.ws_sales_price,
    f.total_sales
FROM 
    customer_data cs
LEFT JOIN 
    filtered_sales f ON cs.c_customer_sk = f.ws_item_sk
LEFT JOIN 
    web_page wp ON wp.wp_customer_sk = cs.c_customer_sk
WHERE 
    (cs.c_current_cdemo_sk IS NOT NULL OR cs.c_first_name IS NOT NULL)
    AND (f.ws_sales_price IS NOT NULL OR f.total_sales >= 500)
ORDER BY 
    cs.c_last_name, cs.c_first_name;
