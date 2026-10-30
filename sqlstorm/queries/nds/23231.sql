
WITH customer_with_returns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned_items,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cwr.total_returned_items,
        RANK() OVER (ORDER BY cwr.total_returned_items DESC) AS rank
    FROM 
        customer_with_returns cwr
    INNER JOIN 
        customer c ON c.c_customer_sk = cwr.c_customer_sk
    WHERE 
        cwr.total_returned_items > 0
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 365
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    sd.total_sales,
    sd.total_profit,
    sd.order_count
FROM 
    top_customers tc
LEFT JOIN 
    sales_data sd ON tc.c_customer_sk = sd.ws_item_sk
WHERE 
    tc.rank <= 10 AND 
    (sd.total_sales IS NULL OR sd.total_sales > 1000)
ORDER BY 
    tc.rank;
