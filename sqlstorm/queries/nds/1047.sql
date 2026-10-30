
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND i.i_item_desc LIKE '%coffee%'
    GROUP BY 
        ws.ws_item_sk
),
customer_returns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year < 1990
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    ss.ws_item_sk,
    COALESCE(ss.total_quantity, 0) AS total_sales_quantity,
    COALESCE(ss.total_net_profit, 0) AS total_sales_net_profit,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    ss.rank
FROM 
    sales_summary ss
FULL OUTER JOIN 
    customer_returns cr ON ss.ws_item_sk = cr.wr_item_sk
WHERE 
    COALESCE(ss.total_net_profit, 0) > 5000 
    OR COALESCE(cr.total_returned_amt, 0) > 1000
ORDER BY 
    ss.rank, total_sales_net_profit DESC;
