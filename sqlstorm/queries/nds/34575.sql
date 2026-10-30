
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sales_price > 100
),
AddressCustomer AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        COUNT(DISTINCT s.ss_item_sk) AS total_items_sold
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales s ON s.ss_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city
),
SalesSummary AS (
    SELECT 
        C.c_customer_id,
        AC.ca_city,
        SUM(SC.ws_quantity) AS total_sales_quantity,
        SUM(SC.ws_sales_price) AS total_sales_amt,
        AVG(SC.ws_sales_price) AS avg_sales_price
    FROM SalesCTE SC
    JOIN customer C ON SC.ws_item_sk = C.c_current_hdemo_sk
    JOIN AddressCustomer AC ON C.c_customer_sk = AC.c_customer_sk
    WHERE SC.rn = 1
    GROUP BY C.c_customer_id, AC.ca_city
)
SELECT 
    S.c_customer_id,
    S.ca_city,
    S.total_sales_quantity,
    S.total_sales_amt,
    S.avg_sales_price,
    COALESCE(NULLIF(S.total_sales_quantity, 0), 0) AS adjusted_quantity,
    CASE 
        WHEN S.total_sales_amt IS NOT NULL THEN S.total_sales_amt 
        ELSE 0 
    END AS adjusted_sales_amt
FROM SalesSummary S
WHERE S.avg_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY S.total_sales_amt DESC
LIMIT 100;
