WITH RankedSales AS (
    SELECT
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY cs_item_sk
),
TopItems AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        RankedSales.total_quantity,
        RankedSales.total_net_profit
    FROM RankedSales
    JOIN item ON RankedSales.cs_item_sk = item.i_item_sk
    WHERE RankedSales.rank <= 10
),
CustomerStats AS (
    SELECT
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
)
SELECT
    TOPItems.i_item_id,
    TOPItems.i_product_name,
    TOPItems.total_quantity,
    TOPItems.total_net_profit,
    CustomerStats.cd_gender,
    CustomerStats.cd_marital_status,
    CustomerStats.avg_purchase_estimate,
    CustomerStats.unique_customers
FROM TopItems
JOIN CustomerStats ON 1=1  
ORDER BY TOPItems.total_net_profit DESC, CustomerStats.avg_purchase_estimate DESC;