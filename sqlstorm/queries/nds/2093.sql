
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns
    GROUP BY sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Mr. ' || c.c_first_name
            ELSE 'Ms. ' || c.c_first_name
        END AS full_name,
        cr.total_returns,
        cr.total_return_amount
    FROM CustomerReturns cr
    JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cr.total_returns > 3
),
StoreSalesData AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS number_of_sales
    FROM store_sales ss
    WHERE ss.ss_sales_price > 20.00
    GROUP BY ss.ss_store_sk
)
SELECT 
    hrc.full_name,
    hrc.total_returns,
    hrc.total_return_amount,
    ssd.total_sales,
    ssd.number_of_sales,
    (SELECT AVG(total_sales) FROM StoreSalesData) AS avg_sales,
    COALESCE((SELECT w.w_warehouse_name FROM warehouse w WHERE w.w_warehouse_sk = ssd.ss_store_sk), 'Unknown') AS warehouse_name
FROM HighReturnCustomers hrc
LEFT JOIN StoreSalesData ssd ON hrc.sr_customer_sk = ssd.ss_store_sk
ORDER BY hrc.total_return_amount DESC;
