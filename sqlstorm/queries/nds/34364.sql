
WITH  SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS ranking
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_sales_price) > 1000
), 
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_orders,
        max(it.i_current_price) AS max_current_price,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM SalesData sd
    LEFT JOIN item it ON sd.ws_item_sk = it.i_item_sk
    LEFT JOIN customer c ON sd.ws_item_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE sd.ranking <= 10
    GROUP BY sd.ws_item_sk, sd.total_sales, sd.total_orders, marital_status
), 
FinalReport AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sales,
        ts.total_orders,
        ts.max_current_price,
        ts.marital_status,
        RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank,
        COALESCE(NULLIF(ts.marital_status, ''), 'Unknown') AS marital_stat
    FROM TopSales ts
)
SELECT 
    fr.ws_item_sk,
    fr.total_sales,
    fr.total_orders,
    fr.max_current_price,
    fr.marital_status,
    fr.sales_rank,
    (SELECT COUNT(*) FROM TopSales) AS total_items
FROM FinalReport fr
WHERE fr.total_sales > (SELECT AVG(total_sales) FROM FinalReport)
ORDER BY fr.total_sales DESC;
