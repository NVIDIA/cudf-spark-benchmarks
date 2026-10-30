
WITH  sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
), 
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(sd.ws_quantity) AS total_quantity_sold,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        AVG(sd.ws_sales_price) AS avg_sales_price,
        COUNT(sd.ws_item_sk) AS sales_count
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rn = 1
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_net_paid) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    i.i_item_id,
    i.total_quantity_sold,
    i.total_sales,
    i.avg_sales_price,
    COALESCE(c.orders_count, 0) AS total_orders,
    COALESCE(c.total_net_profit, 0) AS total_profit,
    COALESCE(c.max_order_value, 0) AS max_order_value
FROM 
    item_performance i
FULL OUTER JOIN 
    customer_analysis c ON i.i_item_sk = c.orders_count
WHERE 
    i.total_quantity_sold IS NOT NULL OR c.orders_count IS NOT NULL
ORDER BY 
    total_sales DESC, total_profit DESC
LIMIT 100;
