
WITH CustomerReturns AS (
    SELECT
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS return_count
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
ReturnsWithDemographics AS (
    SELECT
        cr.cr_returning_customer_sk,
        cr.total_returned,
        cr.total_return_amount,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        cd.hd_income_band_sk,
        cd.hd_buy_potential
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.cr_returning_customer_sk = cd.c_customer_sk
)
SELECT
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    r.cd_marital_status,
    r.ca_city,
    r.ca_state,
    r.hd_income_band_sk,
    r.hd_buy_potential,
    COUNT(r.cr_returning_customer_sk) OVER (PARTITION BY r.cd_gender) AS return_count_by_gender,
    AVG(r.total_return_amount) OVER (PARTITION BY r.cd_gender) AS avg_return_amount_by_gender,
    CASE
        WHEN r.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(r.hd_income_band_sk AS STRING)
    END AS income_band,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = r.cr_returning_customer_sk) AS total_store_sales
FROM ReturnsWithDemographics r
WHERE r.total_returned > 0
ORDER BY r.total_return_amount DESC
LIMIT 100;
