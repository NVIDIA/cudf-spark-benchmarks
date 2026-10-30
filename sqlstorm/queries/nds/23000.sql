
WITH  sales_data AS (
    SELECT
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY
        ws_item_sk, ws_sold_date_sk
),
profit_data AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_sales_price) AS avg_price
    FROM
        store_sales
    WHERE
        ss_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
    GROUP BY
        ss_item_sk
),
returns_summary AS (
    SELECT
        cr_item_sk,
        COUNT(*) AS return_count,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        SUM(cr_return_tax) AS total_return_tax,
        SUM(cr_fee) AS total_fee
    FROM
        catalog_returns
    GROUP BY
        cr_item_sk
),
items AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        COALESCE(d.total_sold, 0) AS web_sales,
        COALESCE(p.total_profit, 0) AS store_profit,
        COALESCE(r.return_count, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount
    FROM
        item i
    LEFT JOIN (
        SELECT
            ws_item_sk,
            SUM(total_sold) AS total_sold
        FROM
            sales_data
        GROUP BY ws_item_sk
    ) d ON i.i_item_sk = d.ws_item_sk
    LEFT JOIN profit_data p ON i.i_item_sk = p.ss_item_sk
    LEFT JOIN returns_summary r ON i.i_item_sk = r.cr_item_sk
),
final AS (
    SELECT
        i_product_name AS product_name,
        web_sales,
        store_profit,
        total_returns,
        total_return_amount,
        (web_sales * 1.0 / NULLIF(total_returns, 0)) AS sales_per_return,
        (store_profit - total_return_amount) AS net_profit
    FROM
        items
    WHERE
        (web_sales > 100 OR store_profit > 500) AND 
        (total_returns > 0 OR total_return_amount < 100)
)
SELECT
    *,
    CASE 
        WHEN sales_per_return IS NULL THEN 'No Sales'
        WHEN sales_per_return < 1 THEN 'High Returns'
        ELSE 'Low Returns'
    END AS return_category
FROM
    final
ORDER BY
    net_profit DESC
LIMIT 100;
