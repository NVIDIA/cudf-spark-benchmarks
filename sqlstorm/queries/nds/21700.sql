
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
),
TopSellingItems AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_sales
    FROM
        RankedSales
    WHERE
        sales_rank = 1
),
StoreSalesData AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS store_total_quantity,
        SUM(ss_net_profit) AS store_total_profit
    FROM
        store_sales
    GROUP BY
        ss_item_sk
),
ItemOverview AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        COALESCE(ts.total_quantity, 0) AS web_total_quantity,
        COALESCE(ts.total_sales, 0) AS web_total_sales,
        COALESCE(ss.store_total_quantity, 0) AS store_total_quantity,
        COALESCE(ss.store_total_profit, 0) AS store_total_profit,
        (COALESCE(ts.total_sales, 0) + COALESCE(ss.store_total_profit, 0)) AS overall_performance
    FROM
        item i
    LEFT JOIN
        TopSellingItems ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN
        StoreSalesData ss ON i.i_item_sk = ss.ss_item_sk
)
SELECT
    io.i_item_id,
    io.web_total_quantity,
    io.store_total_quantity,
    io.overall_performance,
    CASE 
        WHEN io.store_total_quantity > io.web_total_quantity THEN 'Store Dominant'
        WHEN io.web_total_quantity > io.store_total_quantity THEN 'Web Dominant'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM
    ItemOverview io
WHERE
    io.overall_performance > (
        SELECT AVG(overall_performance)
        FROM (
            SELECT 
                (COALESCE(SUM(ws_ext_sales_price), 0) + COALESCE(SUM(ss_net_profit), 0)) AS overall_performance
            FROM 
                store_sales
            LEFT JOIN 
                web_sales ON store_sales.ss_item_sk = web_sales.ws_item_sk
            GROUP BY 
                ws_item_sk
        ) AS temp
    )
ORDER BY
    io.overall_performance DESC
LIMIT 10;
