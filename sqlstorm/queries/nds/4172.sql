
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(sd.order_count, 0) AS order_count,
    COALESCE(sd.total_sales_amount, 0) AS total_sales_amount,
    (COALESCE(sd.total_sales_amount, 0) - COALESCE(cr.total_returned_amount, 0)) AS net_sales,
    CASE 
        WHEN cd.cd_purchase_estimate > 2000 THEN 'High Value'
        WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 2000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM
    CustomerDemographics cd
LEFT JOIN
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
ORDER BY
    net_sales DESC
LIMIT 100;
