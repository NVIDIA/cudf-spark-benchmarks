
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank_quantity
    FROM
        store_returns
    GROUP BY
        sr_item_sk
), 
CustomerData AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE
        cd.cd_marital_status = 'M' AND (cd.cd_purchase_estimate IS NOT NULL)
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent
    FROM
        CustomerData c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        SUM(ws.ws_sales_price) > (SELECT AVG(ws1.ws_sales_price) FROM web_sales ws1)
), 
ReturnAnalysis AS (
    SELECT 
        r.sr_item_sk,
        COALESCE(r.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS sales_value
    FROM
        RankedReturns r
    LEFT JOIN
        web_sales ws ON r.sr_item_sk = ws.ws_item_sk
    GROUP BY 
        r.sr_item_sk, r.total_returned_quantity
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    ra.sr_item_sk,
    ra.returned_quantity,
    ra.sales_value,
    CASE 
        WHEN ra.sales_value > 0 THEN ROUND((ra.returned_quantity / CAST(ra.sales_value AS decimal)) * 100, 2)
        ELSE NULL 
    END AS return_rate_pct
FROM 
    TopCustomers tc
JOIN
    ReturnAnalysis ra ON tc.c_customer_sk IN (SELECT cr_returning_customer_sk FROM catalog_returns WHERE cr_return_quantity > 0)
WHERE
    ra.sales_value > 100
ORDER BY 
    return_rate_pct DESC NULLS LAST
LIMIT 100;
