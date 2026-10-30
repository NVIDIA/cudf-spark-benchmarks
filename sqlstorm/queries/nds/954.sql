
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
),
TopCustomerReturns AS (
    SELECT 
        cr.sr_returned_date_sk,
        cr.sr_item_sk,
        cr.sr_customer_sk,
        cr.sr_return_quantity,
        cr.sr_return_amt,
        cr.sr_return_tax,
        cr.sr_return_amt_inc_tax,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cr.rn = 1
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_paid) > 1000
)
SELECT 
    tcr.c_first_name,
    tcr.c_last_name,
    tcr.ca_city,
    tcr.ca_state,
    ss.total_net_paid,
    ss.total_orders,
    (ss.total_net_paid / NULLIF(ss.total_orders, 0)) AS avg_net_per_order
FROM TopCustomerReturns tcr
JOIN SalesSummary ss ON tcr.sr_item_sk = ss.ws_item_sk
WHERE tcr.sr_return_quantity > 5
    AND (tcr.sr_return_amt > ss.total_net_paid * 0.1 OR tcr.sr_return_tax IS NOT NULL)
ORDER BY avg_net_per_order DESC
LIMIT 10;
