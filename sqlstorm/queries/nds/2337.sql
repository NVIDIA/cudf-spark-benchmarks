
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amt,
        SUM(cr_return_tax) AS total_return_tax,
        COUNT(*) AS return_count
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
), 
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        COUNT(c_customer_sk) AS customer_count
    FROM
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_demo_sk, cd_gender
), 
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales_amt,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cd.cd_gender AS gender,
    COALESCE(sr.return_count, 0) AS total_returns,
    COALESCE(sd.order_count, 0) AS total_orders,
    COALESCE(sd.total_sales_amt, 0) AS total_sales,
    CASE
        WHEN COALESCE(sr.return_count, 0) > 0 THEN 'Returns'
        ELSE 'No Returns'
    END AS return_status
FROM
    CustomerDemographics cd
LEFT JOIN CustomerReturns sr ON cd.cd_demo_sk = sr.cr_returning_customer_sk
LEFT JOIN SalesData sd ON cd.cd_demo_sk = sd.ws_bill_customer_sk
WHERE
    cd.customer_count > 10
GROUP BY
    cd.cd_demo_sk, cd.cd_gender, sr.return_count, sd.order_count, sd.total_sales_amt
ORDER BY
    total_sales DESC,
    total_returns DESC;
