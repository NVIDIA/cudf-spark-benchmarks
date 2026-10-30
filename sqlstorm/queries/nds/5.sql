
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_qty,
        SUM(sr_return_amt) AS total_returned_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
TopCustomers AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt
    FROM
        CustomerDemographics cd
        LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    WHERE
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M' AND
        cd.hd_income_band_sk IS NOT NULL
),
SalesData AS (
    SELECT
        cs_bill_customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk BETWEEN 10000 AND 11000 
    GROUP BY
        cs_bill_customer_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_returned_qty,
    tc.total_returned_amt,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM
    TopCustomers tc
    LEFT JOIN SalesData sd ON tc.c_customer_sk = sd.cs_bill_customer_sk
WHERE
    (tc.total_returned_qty > 5 OR COALESCE(sd.total_sales, 0) > 1000)
ORDER BY
    tc.total_returned_amt DESC,
    COALESCE(sd.total_sales, 0) DESC
LIMIT 10;
