
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ws.ws_item_sk
),
StoreData AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_net_paid) AS store_net_paid
    FROM
        store_sales ss
    WHERE
        ss.ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY
        ss.ss_item_sk
),
CombinedSales AS (
    SELECT
        COALESCE(sd.ws_item_sk, st.ss_item_sk) AS item_sk,
        COALESCE(sd.total_quantity, 0) AS web_quantity,
        COALESCE(st.store_quantity, 0) AS store_quantity,
        (COALESCE(sd.total_net_paid, 0) + COALESCE(st.store_net_paid, 0)) AS total_net_revenue
    FROM
        SalesData sd
    FULL OUTER JOIN
        StoreData st ON sd.ws_item_sk = st.ss_item_sk
),
RankedSales AS (
    SELECT
        item_sk,
        web_quantity,
        store_quantity,
        total_net_revenue,
        RANK() OVER (ORDER BY total_net_revenue DESC) AS revenue_rank
    FROM
        CombinedSales
)
SELECT
    rs.item_sk,
    rs.web_quantity,
    rs.store_quantity,
    rs.total_net_revenue,
    CASE 
        WHEN rs.revenue_rank <= 10 THEN 'Top 10 Item'
        ELSE 'Other'
    END AS category,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_item_sk = rs.item_sk AND sr.sr_returned_date_sk BETWEEN 2400 AND 2450) AS total_returns,
    (SELECT COUNT(*) FROM catalog_returns cr WHERE cr.cr_item_sk = rs.item_sk AND cr.cr_returned_date_sk BETWEEN 2400 AND 2450) AS total_catalog_returns
FROM
    RankedSales rs
WHERE
    rs.web_quantity > 0 OR rs.store_quantity > 0
ORDER BY
    rs.total_net_revenue DESC
LIMIT 50;
