
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
RecentReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_returned_date_sk = (SELECT MAX(cr_returned_date_sk) FROM catalog_returns)
    GROUP BY cr_item_sk
),
CustomerIncome AS (
    SELECT 
        c.c_customer_sk,
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, hd.hd_income_band_sk
)
SELECT 
    ca.ca_city,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_value,
    ci.hd_income_band_sk AS income_band,
    ci.customer_count
FROM customer_address ca
LEFT JOIN (SELECT 
               ws.ws_ship_addr_sk,
               SUM(ws.ws_quantity) AS total_quantity
           FROM web_sales ws
           GROUP BY ws.ws_ship_addr_sk) s ON ca.ca_address_sk = s.ws_ship_addr_sk
LEFT JOIN RecentReturns r ON r.cr_item_sk = (SELECT i_item_sk FROM item WHERE i_item_id = 'ITEM1234567890' LIMIT 1)
LEFT JOIN CustomerIncome ci ON ci.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_first_name = 'John' AND c_last_name = 'Doe' LIMIT 1)
WHERE ca.ca_state = 'NY'
ORDER BY ca.ca_city, income_band DESC
LIMIT 10;
