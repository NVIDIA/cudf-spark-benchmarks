
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= (SELECT MAX(d_date_sk) - 365 FROM date_dim)
),
TotalReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state, ca.ca_zip) AS full_address
    FROM customer_address ca
),
ReturnStats AS (
    SELECT 
        cu.c_customer_sk,
        COALESCE(tr.total_returned, 0) AS total_returned,
        COALESCE(tr.return_count, 0) AS return_count,
        sa.full_address
    FROM customer cu
    LEFT JOIN TotalReturns tr ON cu.c_customer_sk = tr.cr_returning_customer_sk
    LEFT JOIN CustomerAddress sa ON cu.c_current_addr_sk = sa.ca_address_sk
)
SELECT 
    r.ws_order_number,
    r.ws_item_sk,
    r.ws_ship_date_sk,
    r.ws_quantity,
    r.ws_sales_price,
    rel.total_returned,
    rel.return_count,
    CASE WHEN rel.return_count > 0 THEN 'Yes' ELSE 'No' END AS has_returns
FROM RankedSales r
JOIN ReturnStats rel ON r.ws_order_number = rel.c_customer_sk
WHERE r.rank_sales = 1
ORDER BY r.ws_ship_date_sk DESC, r.ws_sales_price DESC;
