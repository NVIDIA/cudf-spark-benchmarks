
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450015 AND 2450615 
    GROUP BY ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.ca_state,
    CASE 
        WHEN ci.cd_purchase_estimate IS NULL THEN 'Estimate Not Available'
        ELSE CAST(ci.cd_purchase_estimate AS STRING)
    END AS purchase_estimate,
    ss.ws_item_sk AS sold_item_sk,
    ss.total_sales,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(r.r_reason_desc, 'No Reason Provided') AS return_reason
FROM SalesCTE ss
LEFT JOIN CustomerInfo ci ON ci.c_customer_sk = ss.ws_item_sk
LEFT JOIN store_returns sr ON sr.sr_item_sk = ss.ws_item_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE ss.profit_rank <= 10  
ORDER BY total_profit DESC;
