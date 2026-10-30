
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TotalPerformance AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_profit,
        rs.order_count,
        CASE 
            WHEN i.i_current_price > 50 THEN 'Premium'
            WHEN i.i_current_price BETWEEN 20 AND 50 THEN 'Standard'
            ELSE 'Budget'
        END AS price_category
    FROM RecursiveSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.ranking <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        COALESCE(rp.total_returns, 0) AS total_returns,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS value_segment
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns rp ON c.c_customer_sk = rp.sr_customer_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status, rp.total_returns, cd.cd_purchase_estimate
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(cd.customer_count) AS total_customers,
    SUM(tp.total_profit) AS total_profit,
    AVG(tp.total_profit) AS avg_profit_per_customer,
    MAX(tp.total_profit) AS max_profit_item,
    MIN(tp.total_profit) AS min_profit_item
FROM CustomerDemographics cd
LEFT JOIN TotalPerformance tp ON cd.customer_count > 0
GROUP BY 
    cd.cd_gender,
    cd.cd_marital_status
HAVING 
    SUM(tp.total_profit) > 10000
ORDER BY 
    total_profit DESC;
