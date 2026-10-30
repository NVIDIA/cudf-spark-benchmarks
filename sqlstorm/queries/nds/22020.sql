
WITH  address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city || ' Suburban' AS ca_city, ca_state, ca_country
    FROM customer_address ca
    WHERE ca_country LIKE 'United%' AND ca_address_sk IN (
        SELECT DISTINCT ca_address_sk
        FROM customer_address
        WHERE ca_city = 'Los Angeles'
    )
), demographic_aggregates AS (
    SELECT cd_gender, 
           COUNT(DISTINCT c_customer_sk) AS customer_count, 
           AVG(cd_purchase_estimate) AS avg_purchase
    FROM customer_demographics 
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender
), sales_data AS (
    SELECT ws_bill_cdemo_sk,
           SUM(ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
    HAVING SUM(ws_net_profit) > 1000
    ORDER BY total_profit DESC
), return_data AS (
    SELECT sr_customer_sk,
           COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
           CASE 
               WHEN COALESCE(SUM(sr_return_quantity), 0) > 0 THEN 'High Return Rate'
               ELSE 'Low Return Rate'
           END AS return_rate_category
    FROM store_returns
    GROUP BY sr_customer_sk
), final_report AS (
    SELECT a.ca_city, 
           a.ca_state, 
           a.ca_country, 
           d.customer_count, 
           d.avg_purchase, 
           s.total_profit, 
           r.total_returns, 
           r.return_rate_category
    FROM address_cte a
    LEFT JOIN demographic_aggregates d ON a.ca_country = 'USA'
    LEFT JOIN sales_data s ON s.ws_bill_cdemo_sk = d.customer_count
    LEFT JOIN return_data r ON r.sr_customer_sk = d.customer_count
    WHERE a.ca_state IN ('CA', 'NY') OR d.avg_purchase > 500
)
SELECT *
FROM final_report
WHERE NOT (total_returns IS NULL AND total_profit < 0);
