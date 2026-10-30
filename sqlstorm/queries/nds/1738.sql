
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > 1000
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        COUNT(DISTINCT c.c_email_address) AS unique_email_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        SUM(ri.ws_quantity) AS total_quantity,
        SUM(ri.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ri
    JOIN 
        ranked_sales r ON ri.ws_item_sk = r.ws_item_sk
    WHERE 
        r.sales_rank <= 10
    GROUP BY 
        ri.ws_item_sk
)
SELECT 
    ci.ws_item_sk,
    ci.total_quantity,
    ci.total_sales_value,
    cs.c_customer_sk,
    cs.female_count,
    cs.male_count,
    cs.unique_email_count,
    CASE 
        WHEN ci.total_sales_value IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    top_items ci
LEFT JOIN 
    customer_stats cs ON cs.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        WHERE c.c_current_cdemo_sk IS NOT NULL
    )
WHERE 
    ci.total_sales_value > 500
ORDER BY 
    ci.total_sales_value DESC
LIMIT 50;
