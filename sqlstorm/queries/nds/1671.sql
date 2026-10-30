
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returned_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
ItemSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), 
ItemReturns AS (
    SELECT 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
SalesPerformance AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(sales.total_sold_quantity, 0) AS total_sold_quantity,
        COALESCE(sales.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(returns.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(returns.total_returned_amount, 0) AS total_returned_amount,
        CASE 
            WHEN COALESCE(sales.total_sold_quantity, 0) > 0 THEN 
                (COALESCE(returns.total_returned_quantity, 0) * 100.0) / COALESCE(sales.total_sold_quantity, 0)
            ELSE 0 
        END AS return_rate
    FROM item i
    LEFT JOIN ItemSales sales ON i.i_item_sk = sales.ws_item_sk
    LEFT JOIN ItemReturns returns ON i.i_item_sk = returns.wr_item_sk
)
SELECT 
    sp.i_item_id, 
    sp.i_item_desc, 
    sp.total_sold_quantity,
    sp.total_sales_amount,
    sp.total_returned_quantity,
    sp.total_returned_amount,
    sp.return_rate,
    CASE 
        WHEN sp.return_rate > 20 THEN 'High Return Rate'
        ELSE 'Normal Return Rate' 
    END AS return_rate_category
FROM SalesPerformance sp
WHERE sp.return_rate > 0
ORDER BY sp.return_rate DESC
LIMIT 10;
