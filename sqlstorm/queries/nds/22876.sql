
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(d.cd_gender, 'U') AS gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price, i.i_brand, d.cd_gender
),
top_items AS (
    SELECT 
        isd.i_item_sk,
        isd.i_item_desc,
        isd.i_current_price,
        isd.i_brand,
        ss.ws_quantity,
        ss.ws_sales_price,
        ss.ws_net_paid,
        ss.sales_rank
    FROM 
        item_details isd
    JOIN sales_summary ss ON isd.i_item_sk = ss.ws_item_sk
    WHERE 
        ss.sales_rank <= 5
)
SELECT 
    ti.i_item_sk,
    ti.i_item_desc,
    ti.i_brand,
    ti.ws_sales_price,
    (ti.ws_sales_price - ti.i_current_price) AS price_difference,
    COUNT(DISTINCT s.ss_ticket_number) AS sale_count,
    SUM(s.ss_net_profit) AS total_profit,
    AVG(ti.ws_sales_price) OVER (PARTITION BY ti.i_brand) AS avg_sales_price_by_brand,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers
FROM 
    top_items ti
LEFT JOIN store_sales s ON ti.i_item_sk = s.ss_item_sk
LEFT JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
WHERE 
    ti.ws_net_paid IS NOT NULL
    AND ti.ws_sales_price > (SELECT AVG(i.i_current_price) FROM item i WHERE i.i_brand = ti.i_brand) 
    AND ti.ws_sales_price IS NOT NULL
GROUP BY 
    ti.i_item_sk, ti.i_item_desc, ti.i_brand, ti.ws_sales_price, ti.i_current_price
ORDER BY 
    total_profit DESC, ti.i_item_desc
LIMIT 5 OFFSET 10;
