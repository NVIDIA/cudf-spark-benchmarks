
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate < 5000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 5000 AND 15000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk AS c_customer_sk,
        SUM(cs.total_sales) AS total_sales_value,
        SUM(cs.order_count) AS total_orders
    FROM SalesSummary cs
    JOIN CustomerDemographics cd ON cs.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY cs.ws_bill_customer_sk
    ORDER BY total_sales_value DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    tc.total_sales_value,
    cd.purchase_band,
    cr.total_returned,
    cr.total_return_value
FROM TopCustomers tc
LEFT JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.c_customer_sk
LEFT JOIN CustomerReturns cr ON tc.c_customer_sk = cr.sr_customer_sk
WHERE (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F') 
      AND (cr.total_returned IS NULL OR cr.total_returned > 5)
ORDER BY tc.total_sales_value DESC;
