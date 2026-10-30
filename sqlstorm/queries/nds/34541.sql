
WITH  sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2458912 AND 2458918 
    GROUP BY
        ws_item_sk
),
top_sales AS (
    SELECT
        ws_item_sk AS ss_item_sk,
        total_quantity,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        sales_summary
    WHERE
        rank = 1
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    (SELECT COUNT(*) FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL) AS total_customers,
    (CASE WHEN ts.total_sales > 10000 THEN 'High' ELSE 'Low' END) AS sales_category,
    CAST('2002-10-01' AS DATE) AS query_date
FROM
    top_sales ts
JOIN
    item i ON ts.ss_item_sk = i.i_item_sk
LEFT JOIN
    store_sales ss ON i.i_item_sk = ss.ss_item_sk
GROUP BY
    i.i_item_id, i.i_item_desc, ts.total_quantity, ts.total_sales
HAVING
    SUM(ss.ss_quantity) IS NULL OR SUM(ss.ss_quantity) < 0
ORDER BY
    ts.total_sales DESC
LIMIT 10;
