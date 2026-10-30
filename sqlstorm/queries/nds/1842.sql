
WITH RankedCustomer AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as PurchaseRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
), RecentSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy = 12
    )
    GROUP BY ws_bill_customer_sk
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(cr.total_returns, 0) > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status,
    CASE 
        WHEN rc.PurchaseRank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM RankedCustomer rc
LEFT JOIN CustomerReturns cr ON rc.c_customer_sk = cr.sr_customer_sk
LEFT JOIN RecentSales rs ON rc.c_customer_sk = rs.ws_bill_customer_sk
ORDER BY rc.cd_gender, total_sales DESC;
