WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM item i2
            WHERE i2.i_rec_start_date <= cast('2002-10-01' as date) AND (i2.i_rec_end_date IS NULL OR i2.i_rec_end_date > cast('2002-10-01' as date))
        ) AND ws.ws_sold_date_sk > (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 1
        )
    GROUP BY
        ws.ws_item_sk
),
StoreSalesSummary AS (
    SELECT
        ss.ss_store_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(ss.ss_ticket_number) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM
        store_sales ss
    WHERE
        ss.ss_sold_date_sk BETWEEN (
            SELECT MIN(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date)) - 1
        ) AND (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = EXTRACT(YEAR FROM cast('2002-10-01' as date))
        )
    GROUP BY
        ss.ss_store_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_quantity, 0) AS store_total_quantity,
    COALESCE(ss.total_sales, 0) AS total_sales_transactions,
    COALESCE(ss.avg_net_profit, 0) AS average_store_profit,
    rs.total_quantity AS top_item_quantity,
    rs.total_net_profit AS top_item_profit
FROM
    store s
LEFT JOIN
    StoreSalesSummary ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN
    RankedSales rs ON rs.rank = 1
WHERE
    s.s_state = 'CA' AND 
    ss.total_quantity > 100
ORDER BY
    s.s_store_name, rs.total_net_profit DESC;