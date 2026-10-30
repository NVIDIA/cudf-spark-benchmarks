
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023
                                AND d_month_seq BETWEEN 1 AND 6)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_current_addr_sk) AS address_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
IncomeDistribution AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    COALESCE(SUM(sd.ws_net_profit), 0) AS total_profit,
    id.customer_count
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON ci.c_customer_sk = sd.ws_item_sk
LEFT JOIN 
    IncomeDistribution id ON ci.c_customer_sk = id.hd_income_band_sk
WHERE 
    (ci.cd_credit_rating IS NOT NULL AND ci.cd_purchase_estimate > 1000)
    OR 
    (ci.cd_marital_status = 'M' AND ci.cd_gender = 'F')
GROUP BY 
    ci.c_customer_sk, ci.cd_gender, ci.cd_marital_status, ci.cd_purchase_estimate, id.customer_count
HAVING 
    COALESCE(SUM(sd.ws_net_profit), 0) > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws)
ORDER BY 
    total_profit DESC;
