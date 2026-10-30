
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk AS customer_id,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
WebReturns AS (
    SELECT
        wr_returning_customer_sk AS customer_id,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_quantity) AS total_return_quantity
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
CombinedReturns AS (
    SELECT 
        customer_id,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_returns) AS total_returns,
        SUM(total_return_quantity) AS total_return_quantity
    FROM (
        SELECT * FROM CustomerReturns
        UNION ALL
        SELECT * FROM WebReturns
    ) AS MergedReturns
    GROUP BY customer_id
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM customer_demographics
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity
    FROM customer AS c
    LEFT JOIN CustomerDemographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CombinedReturns AS cr ON c.c_customer_sk = cr.customer_id
)
SELECT 
    ci.c_customer_sk,
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.total_return_amount,
    ci.total_returns,
    CASE 
        WHEN ci.total_return_amount > 0 THEN 'Returning'
        ELSE 'New'
    END AS customer_status
FROM CustomerInfo AS ci
WHERE 
    ci.cd_marital_status = 'M'
    AND ci.cd_purchase_estimate > (
        SELECT AVG(cd_purchase_estimate) FROM CustomerDemographics
    )
ORDER BY ci.total_return_amount DESC
LIMIT 10;
