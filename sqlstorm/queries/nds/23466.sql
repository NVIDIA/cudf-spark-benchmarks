
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), ws.ws_coupon_amt) AS effective_discount
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
), 
holiday_sales AS (
    SELECT 
        ds.d_date_sk,
        COUNT(DISTINCT rs.ws_item_sk) AS item_count,
        SUM(rs.ws_sales_price) AS total_sales
    FROM date_dim ds
    LEFT JOIN ranked_sales rs ON ds.d_date_sk = rs.ws_sold_date_sk
    WHERE ds.d_holiday = 'Y' AND rs.price_rank <= 3
    GROUP BY ds.d_date_sk
), 
sales_analysis AS (
    SELECT 
        hs.d_date_sk,
        hs.item_count,
        hs.total_sales,
        CASE 
            WHEN hs.total_sales > 1000 THEN 'High Sales'
            WHEN hs.total_sales BETWEEN 500 AND 1000 THEN 'Moderate Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM holiday_sales hs
)
SELECT 
    da.d_date,
    sa.item_count,
    sa.total_sales,
    sa.sales_category,
    COUNT(DISTINCT ca.ca_address_sk) FILTER (WHERE ca.ca_country IS NOT NULL) AS unique_addresses
FROM sales_analysis sa
JOIN date_dim da ON da.d_date_sk = sa.d_date_sk
FULL OUTER JOIN customer_address ca ON ca.ca_country IS NULL
GROUP BY da.d_date, sa.item_count, sa.total_sales, sa.sales_category
HAVING 
    SUM(sa.total_sales) > (SELECT AVG(total_sales) FROM sales_analysis)
    OR MAX(sa.item_count) < 2
ORDER BY da.d_date DESC, sa.total_sales DESC;
