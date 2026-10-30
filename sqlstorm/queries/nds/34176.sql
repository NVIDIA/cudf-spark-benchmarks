
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY ws_item_sk
), 
CustomerGrowth AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
), 
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_estimate,
        COUNT(*) AS demo_count
    FROM customer_demographics cd
    JOIN CustomerGrowth cg ON cd.cd_demo_sk = cg.c_customer_sk
    WHERE cg.total_orders > 5
    GROUP BY cd.cd_gender
    HAVING AVG(cd.cd_purchase_estimate) IS NOT NULL
), 
SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    d.cd_gender,
    d.avg_estimate,
    s.total_sales,
    s.order_count,
    ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY s.total_sales DESC) AS rank_by_sales
FROM DemographicAnalysis d
JOIN SalesSummary s ON d.avg_estimate > s.total_sales
WHERE d.demo_count > 10
ORDER BY d.cd_gender, rank_by_sales
LIMIT 100;
