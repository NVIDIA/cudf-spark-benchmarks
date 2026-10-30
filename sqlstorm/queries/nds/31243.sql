
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        (SELECT COUNT(DISTINCT sr_ticket_number) 
         FROM store_returns 
         WHERE sr_customer_sk = c.c_customer_sk) AS total_returns,
        (SELECT COUNT(DISTINCT wr_order_number) 
         FROM web_returns 
         WHERE wr_returning_customer_sk = c.c_customer_sk) AS total_web_returns
    FROM 
        customer c
),
top_sales AS (
    SELECT 
        s.ws_item_sk, 
        s.total_quantity, 
        s.total_sales,
        c.c_first_name,
        c.total_returns,
        c.total_web_returns
    FROM 
        sales_summary s
    JOIN 
        customer_summary c ON s.ws_sold_date_sk = c.c_customer_sk
    WHERE 
        s.sales_rank <= 10
)
SELECT 
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_returns,
    ts.total_web_returns
FROM 
    top_sales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store s ON i.i_item_sk = s.s_store_sk 
WHERE 
    ts.total_sales > 1000 AND 
    (ts.total_returns IS NOT NULL OR ts.total_web_returns IS NOT NULL)
ORDER BY 
    ts.total_sales DESC, ts.total_quantity ASC;
