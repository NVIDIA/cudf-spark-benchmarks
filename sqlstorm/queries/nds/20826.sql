
WITH RankedSales AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sales_price,
        DENSE_RANK() OVER (PARTITION BY ss_item_sk ORDER BY ss_sales_price DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY ss_store_sk) AS store_sales_count
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
    )
), 
TotalSales AS (
    SELECT
        rs.ss_item_sk,
        rs.ss_sales_price,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
        COUNT(DISTINCT ss.ss_sold_date_sk) AS sale_days_count
    FROM RankedSales rs
    LEFT JOIN web_sales ws ON rs.ss_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON rs.ss_item_sk = ss.ss_item_sk AND rs.ss_store_sk = ss.ss_store_sk
    GROUP BY rs.ss_item_sk, rs.ss_sales_price
),
StoreDetails AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        s.s_country,
        SUM(rs.ss_sales_price) AS store_total_revenue
    FROM store s
    JOIN RankedSales rs ON s.s_store_sk = rs.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, s.s_country
    HAVING SUM(rs.ss_sales_price) > 10000
)
SELECT
    ts.ss_item_sk,
    MIN(ts.ss_sales_price) AS min_price,
    MAX(ts.ss_sales_price) AS max_price,
    AVG(ts.ss_sales_price) AS avg_price,
    sd.s_store_name,
    sd.s_state,
    sd.s_country,
    sd.store_total_revenue,
    ts.total_web_quantity,
    ts.sale_days_count
FROM TotalSales ts
JOIN StoreDetails sd ON ts.ss_item_sk = sd.s_store_sk
WHERE ts.sale_days_count > (
    SELECT AVG(ts2.sale_days_count)
    FROM TotalSales ts2
    WHERE ts2.total_web_quantity > 0
)
GROUP BY 
    ts.ss_item_sk,
    sd.s_store_name,
    sd.s_state, 
    sd.s_country,
    sd.store_total_revenue,
    ts.total_web_quantity,
    ts.sale_days_count
ORDER BY 
    avg_price DESC, 
    min_price ASC;
