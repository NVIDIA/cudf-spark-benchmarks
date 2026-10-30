
WITH Ranked_Sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY ws.ws_item_sk
),
Top_Items AS (
    SELECT
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        COALESCE(r.r_reason_desc, 'No Reason') AS reason_desc
    FROM Ranked_Sales ri
    LEFT JOIN store_returns sr ON sr.sr_item_sk = ri.ws_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE ri.sales_rank <= 10
),
Item_Metrics AS (
    SELECT
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_sales,
        CASE
            WHEN ti.total_sales > 1000 THEN 'High Revenue'
            WHEN ti.total_sales BETWEEN 500 AND 1000 THEN 'Medium Revenue'
            ELSE 'Low Revenue'
        END AS revenue_category,
        INITCAP(ti.reason_desc) AS formatted_reason
    FROM Top_Items ti
)
SELECT
    im.ws_item_sk,
    im.total_quantity,
    im.total_sales,
    im.revenue_category,
    im.formatted_reason,
    CONCAT('Revenue: $', ROUND(im.total_sales, 2)) AS revenue_display
FROM Item_Metrics im
WHERE im.total_quantity > (SELECT AVG(total_quantity) FROM Item_Metrics)
ORDER BY im.total_sales DESC
LIMIT 20;
