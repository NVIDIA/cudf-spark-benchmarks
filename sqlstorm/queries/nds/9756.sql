
WITH return_details AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk, wr_item_sk
),
sales_details AS (
    SELECT 
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_ext_sales_price) AS total_sold_amount
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk, ws_item_sk
),
combined_details AS (
    SELECT 
        r.wr_returning_customer_sk AS customer_sk,
        r.wr_item_sk AS item_sk,
        COALESCE(r.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(r.total_returned_amount, 0) AS returned_amount,
        COALESCE(s.total_sold_quantity, 0) AS sold_quantity,
        COALESCE(s.total_sold_amount, 0) AS sold_amount,
        (COALESCE(s.total_sold_quantity, 0) - COALESCE(r.total_returned_quantity, 0)) AS net_quantity,
        (COALESCE(s.total_sold_amount, 0) - COALESCE(r.total_returned_amount, 0)) AS net_amount
    FROM 
        return_details r
    FULL OUTER JOIN
        sales_details s ON r.wr_returning_customer_sk = s.ws_ship_customer_sk AND r.wr_item_sk = s.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cb.returned_quantity,
    cb.returned_amount,
    cb.sold_quantity,
    cb.sold_amount,
    cb.net_quantity,
    cb.net_amount
FROM 
    customer c
JOIN 
    combined_details cb ON c.c_customer_sk = cb.customer_sk
WHERE 
    cb.net_quantity < 0
ORDER BY 
    cb.net_amount ASC
LIMIT 100;
