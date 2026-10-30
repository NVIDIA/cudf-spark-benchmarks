
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
), 
CustomerReturns AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COUNT(rs.ws_order_number) AS total_orders,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    SUM(CASE WHEN rs.rank = 1 THEN rs.ws_sales_price ELSE 0 END) AS total_highest_price_sales
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1970 AND 1990
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cr.total_return_amt
HAVING 
    SUM(rs.ws_sales_price) IS NOT NULL
ORDER BY 
    total_return_amt DESC, total_orders DESC
LIMIT 100;
