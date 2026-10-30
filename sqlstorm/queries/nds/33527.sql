
WITH  sales_cte AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk >= 20200101
    UNION ALL
    SELECT cs_sold_date_sk, cs_item_sk, cs_quantity, cs_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk >= 20200101
), aggregated_sales AS (
    SELECT 
        COALESCE(NULLIF(ws.ws_item_sk, 0), cs.cs_item_sk) AS item_sk,
        SUM(ws.ws_quantity + COALESCE(cs.cs_quantity, 0)) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_web_sales_price,
        AVG(cs.cs_sales_price) AS avg_catalog_sales_price
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    GROUP BY COALESCE(NULLIF(ws.ws_item_sk, 0), cs.cs_item_sk)
), customer_ranking AS (
    SELECT 
        c.c_customer_sk,
        DENSE_RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
), eligible_customers AS (
    SELECT c_customer_sk
    FROM customer_ranking
    WHERE customer_rank <= 100
)
SELECT 
    a.item_sk,
    a.total_quantity,
    a.avg_web_sales_price,
    a.avg_catalog_sales_price,
    COUNT(DISTINCT ec.c_customer_sk) AS eligible_customers_count
FROM aggregated_sales a
LEFT JOIN eligible_customers ec ON a.item_sk IN (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    UNION
    SELECT cs_item_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 20220101 AND 20221231
)
GROUP BY a.item_sk, a.total_quantity, a.avg_web_sales_price, a.avg_catalog_sales_price
HAVING (a.avg_web_sales_price + a.avg_catalog_sales_price) > 50.00
ORDER BY a.total_quantity DESC;
