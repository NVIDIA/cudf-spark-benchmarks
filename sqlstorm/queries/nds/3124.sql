
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales_amount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
        CASE 
            WHEN COALESCE(cr.total_returned, 0) > 0 
            THEN 'active'
            ELSE 'inactive'
        END AS customer_status
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.total_returned,
    c.total_return_amount,
    c.total_sales_quantity,
    c.total_sales_amount,
    c.customer_status,
    RANK() OVER (PARTITION BY c.customer_status ORDER BY c.total_sales_amount DESC) AS sales_rank
FROM CustomerAnalysis c
WHERE c.total_sales_amount > (SELECT AVG(total_sales_amount) FROM SalesData) 
AND c.cd_gender IS NOT NULL
ORDER BY c.customer_status, sales_rank
