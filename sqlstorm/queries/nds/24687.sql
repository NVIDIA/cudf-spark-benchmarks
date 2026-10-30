
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.order_count, 
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS customer_rank
    FROM customer_sales cs
),
item_averages AS (
    SELECT 
        i.i_item_sk,
        AVG(ws.ws_sales_price - ws.ws_ext_discount_amt) AS avg_sale_price,
        COUNT(ws.ws_order_number) AS total_sales
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    cu.c_customer_sk,
    cu.order_count,
    cu.total_profit,
    ia.i_item_sk,
    ia.avg_sale_price,
    (SELECT COUNT(DISTINCT sr.sr_ticket_number) 
     FROM store_returns sr 
     WHERE sr.sr_item_sk = ia.i_item_sk 
     AND sr.sr_return_quantity > 0) AS total_returns,
    (CASE 
        WHEN cu.order_count > 10 THEN 'High' 
        WHEN cu.order_count BETWEEN 5 AND 10 THEN 'Medium' 
        ELSE 'Low' 
    END) AS customer_segment
FROM top_customers cu
JOIN item_averages ia ON ia.total_sales > 0
WHERE cu.customer_rank <= 5
ORDER BY cu.total_profit DESC, ia.avg_sale_price ASC
LIMIT 10;
