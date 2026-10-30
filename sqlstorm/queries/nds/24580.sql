WITH  CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
), 
ReturnSummary AS (
    SELECT 
        cr.sr_customer_sk,
        SUM(cr.sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT cr.sr_item_sk) AS unique_items_returned
    FROM CustomerReturns cr
    WHERE cr.rn <= 5  
    GROUP BY cr.sr_customer_sk
),
RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.unique_items_returned, 0) AS unique_items_returned,
        RANK() OVER (ORDER BY COALESCE(rs.total_returned_quantity, 0) DESC) AS customer_rank
    FROM customer c
    LEFT JOIN ReturnSummary rs ON c.c_customer_sk = rs.sr_customer_sk
),
HighlyActiveCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_returned_quantity,
        r.unique_items_returned
    FROM RankedCustomers r
    WHERE r.customer_rank <= 10
),
SalesHistory AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_sales_price) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_item_sk) AS total_items_purchased
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    hac.c_customer_sk,
    hac.c_first_name,
    hac.c_last_name,
    hac.total_returned_quantity,
    hac.unique_items_returned,
    COALESCE(sh.total_spent, 0) AS total_spent,
    COALESCE(sh.total_orders, 0) AS total_orders,
    COALESCE(sh.total_items_purchased, 0) AS total_items_purchased,
    CASE 
        WHEN hac.total_returned_quantity > 10 THEN 'Frequent Returner'
        WHEN hac.unique_items_returned > 5 THEN 'Diverse Purchaser'
        ELSE 'Standard Customer'
    END AS customer_category
FROM HighlyActiveCustomers hac
LEFT JOIN SalesHistory sh ON hac.c_customer_sk = sh.customer_sk
WHERE NOT (hac.total_returned_quantity IS NULL AND sh.total_spent = 0)
ORDER BY hac.total_returned_quantity DESC, total_spent DESC
LIMIT 100;