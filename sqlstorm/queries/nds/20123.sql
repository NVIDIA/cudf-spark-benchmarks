
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN cd_demo_sk END) AS marital_customers,
        COUNT(DISTINCT cd_demo_sk) AS total_customers,
        MAX(cd_purchase_estimate) AS max_estimate,
        MIN(cd_purchase_estimate) AS min_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
), 
IncomeData AS (
    SELECT 
        h.hd_demo_sk, 
        COUNT(hd_buy_potential) FILTER (WHERE hd_buy_potential IS NOT NULL) AS count_potential,
        SUM(CASE WHEN ib_lower_bound IS NOT NULL THEN (ib_lower_bound + ib_upper_bound) / 2 ELSE 0 END) AS avg_income
    FROM household_demographics h
    LEFT JOIN income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY h.hd_demo_sk
)
SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(kr.return_amt) AS total_return_amt,
    cs.marital_customers,
    cs.total_customers,
    cs.max_estimate,
    cs.min_estimate,
    ROUND(AVG(income.avg_income), 2) AS avg_income_band
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS return_amt
     FROM
        RankedReturns
     WHERE 
        rnk = 1
     GROUP BY sr_item_sk) kr ON kr.sr_item_sk = c.c_customer_sk
JOIN 
    CustomerStats cs ON cs.c_customer_sk = c.c_customer_sk
JOIN 
    IncomeData income ON income.hd_demo_sk = c.c_current_hdemo_sk
WHERE 
    ca.ca_city IS NOT NULL AND
    (c.c_first_shipto_date_sk IS NOT NULL OR c.c_first_sales_date_sk IS NOT NULL)
GROUP BY 
    c.c_customer_id, ca.ca_city, cs.marital_customers, cs.total_customers, cs.max_estimate, cs.min_estimate
HAVING 
    SUM(kr.return_amt) > 100.00 OR COUNT(kr.return_amt) > 5 
ORDER BY 
    total_return_amt DESC
LIMIT 100;
