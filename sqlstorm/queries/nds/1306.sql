
WITH RankedSales AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
TopProfitableItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_profit,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY rs.total_profit DESC) AS item_rank
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.rank = 1
),
StoreSalesAggregates AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_profit) AS total_store_profit
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
StoreRankedProfits AS (
    SELECT
        s.s_store_sk,
        ss.total_store_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_store_profit DESC) AS store_rank
    FROM
        store s
    JOIN
        StoreSalesAggregates ss ON s.s_store_sk = ss.ss_store_sk
)
SELECT
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_profit,
    tsi.i_item_desc,
    sr.total_store_profit,
    sr.store_rank
FROM
    TopProfitableItems tsi
JOIN
    StoreRankedProfits sr ON sr.store_rank <= 5
WHERE
    tsi.total_profit >= (
        SELECT
            AVG(total_profit)
        FROM
            TopProfitableItems
    )
ORDER BY
    tsi.total_profit DESC, sr.total_store_profit DESC;
