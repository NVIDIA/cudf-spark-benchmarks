WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
          AND ws.ws_sales_price > (
              SELECT AVG(ws_inner.ws_sales_price)
              FROM web_sales ws_inner
              WHERE ws_inner.ws_item_sk = ws.ws_item_sk
          )
),
HighVolumeReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_item_sk
    HAVING
        SUM(sr_return_quantity) > 50
)
SELECT
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    ROUND(AVG(ws.ws_net_profit), 2) AS average_net_profit,
    ARRAY_AGG(DISTINCT r.r_reason_desc) AS reason_descs
FROM
    customer_address ca
JOIN
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    HighVolumeReturns hvr ON ws.ws_item_sk = hvr.sr_item_sk
LEFT JOIN
    reason r ON hvr.sr_item_sk = r.r_reason_sk
WHERE
    ca.ca_state = 'CA'
    AND (ws.ws_sales_price IS NOT NULL OR hvr.total_return_quantity IS NOT NULL)
    AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month = 12) 
GROUP BY
    ca.ca_city
HAVING
    COUNT(DISTINCT c.c_customer_id) > (SELECT COUNT(*) / 10 FROM customer)  
ORDER BY
    average_net_profit DESC
LIMIT 5;