
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk = ws.ws_item_sk AND p.p_discount_active = 'Y')
),
high_value_sales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.total_quantity,
        COALESCE(NULLIF(rs.ws_sales_price, 0), NULL) AS safe_sales_price
    FROM
        ranked_sales rs
    WHERE
        rs.price_rank = 1
        AND rs.total_quantity > 100
),
combined_returns AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr_order_number) AS unique_returns
    FROM
        catalog_returns
    GROUP BY
        cr_item_sk
),
final_report AS (
    SELECT
        hvs.ws_item_sk,
        hvs.ws_order_number,
        hvs.safe_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.unique_returns, 0) AS unique_returns,
        CASE
            WHEN hvs.total_quantity > 500 THEN 'High'
            WHEN hvs.total_quantity BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM
        high_value_sales hvs
    LEFT JOIN
        combined_returns cr ON hvs.ws_item_sk = cr.cr_item_sk
)
SELECT
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.safe_sales_price,
    fr.total_returns,
    fr.unique_returns,
    fr.sales_category,
    CASE 
        WHEN fr.safe_sales_price > (SELECT AVG(safe_sales_price) FROM high_value_sales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS price_comparison
FROM
    final_report fr
WHERE
    fr.total_returns IS NOT NULL
ORDER BY
    fr.sales_category DESC, fr.safe_sales_price DESC
LIMIT 100;
