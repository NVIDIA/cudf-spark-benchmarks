
WITH RankedSales AS (
    SELECT 
        ws_web_site_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_web_site_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, ca.ca_city, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(rs.total_quantity) AS total_sales,
    SUM(rs.total_profit) AS total_profit,
    COALESCE(SUM(ir.total_returns), 0) AS total_returns,
    COALESCE(SUM(ir.total_return_value), 0) AS total_return_value,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    CASE 
        WHEN COUNT(DISTINCT ci.c_customer_sk) > 0 THEN 
            SUM(rs.total_profit) / COUNT(DISTINCT ci.c_customer_sk)
        ELSE 0 
    END AS avg_profit_per_customer
FROM RankedSales rs
JOIN CustomerInfo ci ON rs.ws_web_site_sk = ci.c_customer_sk
LEFT JOIN ItemReturns ir ON rs.ws_item_sk = ir.sr_item_sk
WHERE ci.cd_credit_rating IS NOT NULL
  AND ci.cd_credit_rating IN (SELECT cd_credit_rating FROM customer_demographics WHERE cd_marital_status = 'M')
  AND ci.ca_city NOT IN ('Unknown', 'Other')
GROUP BY ci.ca_city, ci.cd_gender, ci.cd_marital_status
HAVING CASE 
           WHEN COUNT(DISTINCT ci.c_customer_sk) > 0 THEN 
               SUM(rs.total_profit) / COUNT(DISTINCT ci.c_customer_sk)
           ELSE 0 
       END > (SELECT AVG(ws.ws_net_profit) 
               FROM web_sales ws 
               WHERE ws.ws_item_sk IN (SELECT ir.sr_item_sk FROM ItemReturns ir WHERE ir.total_returns > 0))
ORDER BY total_sales DESC, total_profit DESC
LIMIT 10;
