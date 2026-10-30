
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown' 
            ELSE cd.cd_credit_rating 
        END AS credit_status
    FROM customer_demographics cd
),
SalesWithReturns AS (
    SELECT
        sd.c_customer_sk,
        sd.total_sales,
        sd.order_count,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value
    FROM SalesData sd
    LEFT JOIN CustomerReturns cr ON sd.c_customer_sk = cr.sr_customer_sk
)
SELECT
    swr.c_customer_sk,
    swr.total_sales,
    swr.order_count,
    swr.total_returns,
    swr.total_return_value,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_status
FROM SalesWithReturns swr
JOIN CustomerDemographics cd ON swr.c_customer_sk = cd.cd_demo_sk
WHERE swr.total_sales > 1000
ORDER BY swr.total_return_value DESC, swr.total_sales DESC
LIMIT 50;
