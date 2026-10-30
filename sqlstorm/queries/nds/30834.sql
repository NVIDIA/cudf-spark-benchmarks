
WITH  CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_returns,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_returns,
        COUNT(DISTINCT cr.cr_order_number) AS total_cr_returns,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COUNT(DISTINCT cr.cr_order_number) DESC) AS rn
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN catalog_sales cs ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
    GROUP BY c.c_customer_sk, c.c_customer_id
),
HighReturnCustomers AS (
    SELECT 
        c.c_customer_id, 
        SUM(total_web_returns + total_catalog_returns) AS total_returns
    FROM customer c
    INNER JOIN CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(total_web_returns + total_catalog_returns) > 1000
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hrc.total_returns,
    (SELECT COUNT(DISTINCT ws.ws_order_number)
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_orders,
    (SELECT AVG(ws.ws_net_paid)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS average_order_value
FROM HighReturnCustomers hrc
JOIN customer c ON hrc.c_customer_id = c.c_customer_id
ORDER BY hrc.total_returns DESC
LIMIT 10;
