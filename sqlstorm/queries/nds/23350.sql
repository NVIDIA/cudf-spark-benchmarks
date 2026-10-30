
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(*) DESC) AS rn
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
TopItems AS (
    SELECT 
        sr_item_sk,
        SUM(total_return_amt) AS total_returned_value,
        AVG(return_count) AS avg_return_per_date
    FROM RankedReturns
    WHERE rn = 1
    GROUP BY sr_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        t.total_returned_value,
        t.avg_return_per_date
    FROM item i
    JOIN TopItems t ON i.i_item_sk = t.sr_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM((SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk)) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
SalesAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ss.ss_net_profit) > 50000
)
SELECT 
    id.i_item_id,
    id.i_item_desc,
    id.i_current_price,
    COALESCE(cda.customer_count, 0) AS customer_count,
    COALESCE(cda.total_sales, 0) AS total_sales,
    COALESCE(sa.total_net_profit, 0) AS total_net_profit,
    id.total_returned_value,
    id.avg_return_per_date
FROM ItemDetails id
LEFT JOIN CustomerDemographics cda ON id.i_item_id LIKE '%' || cda.cd_gender || '%'
LEFT JOIN SalesAnalysis sa ON cda.cd_gender = sa.cd_gender AND cda.cd_marital_status = sa.cd_marital_status
WHERE id.total_returned_value IS NOT NULL
  AND id.avg_return_per_date IS NOT NULL
ORDER BY id.total_returned_value DESC
LIMIT 100;
