
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk AS sold_date,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
        AND i.i_category = 'Electronics'
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
), 
top_sales AS (
    SELECT 
        sold_date,
        item_sk,
        total_quantity,
        total_sales,
        avg_net_profit,
        RANK() OVER (PARTITION BY sold_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
)
SELECT 
    t.sold_date,
    t.item_sk,
    t.total_quantity,
    t.total_sales,
    t.avg_net_profit
FROM 
    top_sales t
WHERE 
    t.sales_rank <= 5
ORDER BY 
    t.sold_date, 
    t.total_sales DESC;
