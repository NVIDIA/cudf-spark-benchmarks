
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451007 AND 2451337  
    GROUP BY ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_purchase_estimate > 10000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesComparison AS (
    SELECT
        R.ws_item_sk,
        R.total_quantity,
        R.total_sales,
        HS.return_count,
        HS.total_return_amt,
        HS.total_return_quantity,
        CASE 
            WHEN HS.total_return_amt IS NULL THEN 'No Returns'
            WHEN R.total_sales > HS.total_return_amt THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profitability_status
    FROM RankedSales R
    LEFT JOIN ReturnStats HS ON R.ws_item_sk = HS.sr_item_sk
)
SELECT
    SC.ws_item_sk,
    SC.total_quantity,
    SC.total_sales,
    SC.return_count,
    SC.total_return_amt,
    SC.total_return_quantity,
    H.customer_value_category,
    H.cd_gender,
    H.cd_marital_status
FROM SalesComparison SC
JOIN HighValueCustomers H ON SC.ws_item_sk IN (
    SELECT DISTINCT ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk IN (
        SELECT DISTINCT c_customer_sk
        FROM customer
        WHERE c_customer_id LIKE 'C%'
    )
)
ORDER BY SC.total_sales DESC, SC.return_count DESC
LIMIT 100;
