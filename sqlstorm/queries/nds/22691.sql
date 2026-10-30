
WITH RankedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY i.i_current_price DESC) AS price_rank
    FROM item i
    WHERE i.i_rec_end_date > DATE '2002-10-01'
),

SalesStats AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 20000
    GROUP BY ws.ws_item_sk
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' OR cd.cd_gender IS NULL
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)

SELECT 
    ci.i_item_id,
    ci.i_item_desc,
    COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(ss.total_net_profit, 0.00) AS total_net_profit,
    ci.i_current_price,
    cd.customer_count,
    cd.avg_purchase_estimate,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Customers'
        WHEN cd.avg_purchase_estimate >= 1000 THEN 'High Potential'
        ELSE 'Regular Customer'
    END AS customer_potential
FROM RankedItems ci
LEFT JOIN SalesStats ss ON ci.i_item_sk = ss.ws_item_sk
LEFT JOIN CustomerDemographics cd ON cd.customer_count > 10 AND cd.cd_demo_sk = (
    SELECT MAX(cd2.cd_demo_sk)
    FROM CustomerDemographics cd2 
    WHERE cd2.customer_count IS NOT NULL
)
WHERE ci.price_rank <= 5
ORDER BY total_net_profit DESC
LIMIT 100 OFFSET 50;
