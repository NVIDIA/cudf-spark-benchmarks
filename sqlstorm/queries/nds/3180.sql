
WITH ranked_sales AS (
    SELECT 
        ws_web_page_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_web_page_sk ORDER BY ws_net_profit DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        web_page.wp_web_page_sk,
        web_page.wp_url,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
    FROM 
        web_sales ws 
    INNER JOIN 
        web_page ON ws.ws_web_page_sk = web_page.wp_web_page_sk
    LEFT JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    GROUP BY 
        web_page.wp_web_page_sk, web_page.wp_url
)
SELECT 
    s.wp_web_page_sk,
    s.wp_url,
    ss.total_quantity,
    ss.total_sales,
    ss.unique_customers,
    COALESCE((SELECT AVG(ws_sales_price) 
              FROM web_sales 
              WHERE ws_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE rank_sales <= 10)), 0) AS average_top_sales_price
FROM 
    sales_summary ss
JOIN 
    web_page s ON ss.wp_web_page_sk = s.wp_web_page_sk
LEFT OUTER JOIN 
    ranked_sales rs ON s.wp_web_page_sk = rs.ws_web_page_sk
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary) 
    AND ss.unique_customers > 5
ORDER BY 
    ss.total_sales DESC
LIMIT 50;
