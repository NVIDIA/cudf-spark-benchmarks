
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
highest_sales AS (
    SELECT 
        ws_item_sk,
        RANK() OVER (ORDER BY total_profit DESC) AS sales_rank
    FROM 
        sales_summary
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        hs.sales_rank
    FROM 
        item i
    JOIN 
        highest_sales hs ON i.i_item_sk = hs.ws_item_sk
    WHERE 
        hs.sales_rank <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_customer_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    cs.c_customer_id,
    cs.total_customer_profit,
    cs.order_count
FROM 
    item_details id
LEFT OUTER JOIN 
    customer_sales cs ON cs.total_customer_profit > 0
WHERE 
    cs.total_customer_profit IS NOT NULL
ORDER BY 
    id.i_current_price DESC, cs.total_customer_profit DESC;
