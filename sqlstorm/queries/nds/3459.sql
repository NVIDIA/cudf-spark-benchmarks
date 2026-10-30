WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452088 AND 2452420 
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(ws.ws_quantity), 0) AS quantity_sold
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    cd.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(rs.total_profit) AS total_profit,
    COUNT(DISTINCT id.i_item_sk) AS unique_items_sold,
    AVG(id.quantity_sold) AS avg_quantity_per_item,
    CASE 
        WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
        ELSE 'Has Dependents'
    END AS dependents_status,
    RANK() OVER (ORDER BY SUM(rs.total_profit) DESC) AS customer_rank
FROM RankedSales rs
JOIN CustomerDemographics cd ON rs.ws_bill_customer_sk = cd.c_customer_sk
JOIN ItemDetails id ON rs.ws_bill_customer_sk = id.i_item_sk
WHERE rs.profit_rank <= 10
GROUP BY 
    cd.c_customer_sk, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status,
    cd.cd_dep_count
ORDER BY total_profit DESC;