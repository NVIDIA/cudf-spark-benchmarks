WITH SalesSummary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
TopProfitableItems AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        SUM(ss_quantity) AS store_total_sold,
        SUM(ss_net_profit) AS store_total_profit
    FROM
        store_sales
    GROUP BY
        ss_item_sk, ss_store_sk
),
CombinedSales AS (
    SELECT
        tpi.ss_item_sk,
        tpi.store_total_sold,
        tpi.store_total_profit,
        ss.total_sold,
        ss.total_profit,
        ss.order_count
    FROM
        TopProfitableItems tpi
    JOIN
        SalesSummary ss
    ON
        tpi.ss_item_sk = ss.ws_item_sk
),
RankedItems AS (
    SELECT
        cs.ss_item_sk,
        cs.store_total_sold,
        cs.store_total_profit,
        cs.total_sold,
        cs.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.ss_item_sk ORDER BY cs.store_total_profit DESC) AS rnk
    FROM
        CombinedSales cs
)
SELECT
    ri.ss_item_sk,
    ri.store_total_sold,
    ri.store_total_profit,
    ri.total_sold,
    ri.total_profit
FROM
    RankedItems ri
WHERE
    ri.rnk = 1
    AND ri.total_profit IS NOT NULL
ORDER BY
    ri.store_total_profit DESC
LIMIT 10;