
WITH RecursiveReturns AS (
    SELECT
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_refunds,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS rn
    FROM web_returns
    GROUP BY wr_returning_customer_sk, wr_item_sk
    HAVING SUM(wr_return_quantity) IS NOT NULL
),
TotalSales AS (
    SELECT
        ws_ship_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales
    FROM web_sales
    GROUP BY ws_ship_customer_sk, ws_item_sk
),
AddressedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    a.c_first_name,
    a.c_last_name,
    a.ca_city,
    a.ca_state,
    r.total_refunds,
    COALESCE(s.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(s.total_sales, 0) > 0 THEN (r.total_refunds / CAST(s.total_sales AS decimal)) * 100
        ELSE NULL 
    END AS refund_percentage
FROM AddressedCustomers a
LEFT JOIN RecursiveReturns r ON a.c_customer_sk = r.wr_returning_customer_sk
LEFT JOIN TotalSales s ON a.c_customer_sk = s.ws_ship_customer_sk
WHERE (a.ca_state = 'CA' OR a.ca_state = 'TX')
AND (r.total_refunds IS NOT NULL OR s.total_sales IS NOT NULL)
ORDER BY refund_percentage DESC
LIMIT 10;
