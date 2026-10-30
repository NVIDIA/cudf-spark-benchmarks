
WITH  sales_summary AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk, ws_item_sk
),
returns_summary AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM
        web_returns
    GROUP BY
        wr_item_sk
),
promotions AS (
    SELECT 
        p_item_sk,
        COUNT(DISTINCT p_promo_id) AS promo_count
    FROM 
        promotion
    WHERE 
        p_discount_active = 'Y'
    GROUP BY 
        p_item_sk
)

SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.total_sales, 0) AS total_sales_value,
    COALESCE(rs.total_returned, 0) AS total_returns,
    COALESCE(p.promo_count, 0) AS active_promotions,
    (COALESCE(ss.total_sales, 0) - COALESCE(rs.total_returned, 0)) AS net_sales,
    CASE 
        WHEN COALESCE(ss.total_sales, 0) = 0 THEN NULL 
        ELSE (COALESCE(rs.total_returned, 0) * 100.0 / COALESCE(ss.total_sales, 0)) 
    END AS return_percentage
FROM
    item i
LEFT JOIN
    sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN
    returns_summary rs ON i.i_item_sk = rs.wr_item_sk
LEFT JOIN
    promotions p ON i.i_item_sk = p.p_item_sk
WHERE
    (COALESCE(ss.total_quantity, 0) > 100 OR COALESCE(rs.total_returned, 0) > 10)
ORDER BY
    net_sales DESC
LIMIT 50;
