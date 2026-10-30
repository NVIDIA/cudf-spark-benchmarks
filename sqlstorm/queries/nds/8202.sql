
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        d_year,
        d_month_seq
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year BETWEEN 2021 AND 2023
    GROUP BY ws_item_sk, d_year, d_month_seq
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
),
CustomerStats AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    JOIN customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk
),
FinalResults AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        cs.customer_count,
        cs.avg_purchase_estimate
    FROM TopItems ti
    JOIN CustomerStats cs ON cs.customer_count > 0
    WHERE sales_rank <= 10
)
SELECT 
    i.i_item_id,
    fr.total_quantity,
    fr.total_sales,
    fr.customer_count,
    fr.avg_purchase_estimate
FROM FinalResults fr
JOIN item i ON fr.ws_item_sk = i.i_item_sk
ORDER BY fr.total_sales DESC;
