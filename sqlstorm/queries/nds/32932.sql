
WITH  SalesData AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_paid) AS total_sales,
        COUNT(*) AS sales_count
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_order_number
    HAVING
        SUM(ws_net_paid) > 100
    UNION ALL
    SELECT
        cs_item_sk,
        cs_order_number,
        SUM(cs_net_paid) AS total_sales,
        COUNT(*) AS sales_count
    FROM
        catalog_sales
    GROUP BY
        cs_item_sk, cs_order_number
    HAVING
        SUM(cs_net_paid) > 100
),
RankedSales AS (
    SELECT
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.total_sales,
        sd.sales_count,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    SUM(rs.total_sales) AS total_revenue,
    AVG(rs.sales_count) AS avg_sales_count,
    COUNT(DISTINCT rs.ws_order_number) AS unique_orders,
    COALESCE(
        STRING_AGG(CONCAT_WS(':', rs.ws_order_number, CAST(rs.total_sales AS STRING)), ', '),
        'No Orders') AS order_list
FROM
    RankedSales rs
JOIN
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE
    rs.sales_count IS NOT NULL
    AND (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_item_sk = rs.ws_item_sk) > 0
GROUP BY
    i.i_item_id, i.i_item_desc
HAVING
    SUM(rs.total_sales) > 1000
ORDER BY
    total_revenue DESC
LIMIT 10;
