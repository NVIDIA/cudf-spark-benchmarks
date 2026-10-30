
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        DATE(d.d_date) AS sold_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, d.d_date, d.d_year
),
top_sales AS (
    SELECT 
        sold_date,
        total_quantity,
        total_net_profit,
        total_orders
    FROM 
        sales_summary
    WHERE 
        profit_rank <= 10
),
customer_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT wr_order_number) AS total_returned_orders
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(ts.total_quantity, 0) AS total_quantity_purchased,
    COALESCE(ts.total_net_profit, 0) AS total_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_orders, 0) AS total_returned_orders,
    (COALESCE(ts.total_net_profit, 0) - COALESCE(cr.total_returned_quantity, 0) * 
        (SELECT AVG(ws.ws_list_price) 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk)) AS net_profit_after_returns
FROM 
    customer c
LEFT JOIN 
    top_sales ts ON c.c_customer_sk = ts.total_orders
LEFT JOIN 
    customer_returns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    c.c_current_addr_sk IS NOT NULL
ORDER BY 
    net_profit_after_returns DESC
LIMIT 100;
