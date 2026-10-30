
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount
    FROM
        catalog_returns
    GROUP BY
        cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_income_band_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesInfo AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity,
        ws_bill_customer_sk
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_bill_customer_sk
),
ReturnRates AS (
    SELECT
        cd.full_name,
        cd.gender,
        cd.cd_marital_status,
        SUM(COALESCE(cr.total_returns, 0)) AS total_returns,
        SUM(COALESCE(si.total_sales_price, 0)) AS total_sales,
        CASE 
            WHEN SUM(COALESCE(si.total_sales_price, 0)) > 0 THEN SUM(COALESCE(cr.total_returns, 0)) * 1.0 / SUM(COALESCE(si.total_sales_price, 0))
            ELSE NULL
        END AS return_rate
    FROM
        CustomerDemographics cd
    LEFT JOIN
        CustomerReturns cr ON cd.c_customer_sk = cr.cr_returning_customer_sk
    LEFT JOIN
        SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY
        cd.full_name, cd.gender, cd.cd_marital_status
)
SELECT
    *,
    CASE 
        WHEN return_rate IS NULL THEN 'No Sales'
        WHEN return_rate > 0.1 THEN 'High Return Rate'
        WHEN return_rate > 0.05 THEN 'Moderate Return Rate'
        ELSE 'Low Return Rate'
    END AS return_rate_category
FROM
    ReturnRates
ORDER BY
    return_rate DESC NULLS LAST;
