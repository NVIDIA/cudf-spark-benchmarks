WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_quantity,
        cs_sales_price,
        cs_ext_sales_price,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_order_number DESC) AS rank_order
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2001 AND d_month_seq IN (6, 7, 8)
    )
),
SalesSummary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_sales_price) AS avg_sales_price,
        MAX(cs_ext_sales_price) AS max_sales_price,
        MIN(cs_ext_sales_price) AS min_sales_price
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2000) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    GROUP BY cs_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_quantity, 0) AS total_quantity,
    COALESCE(ss.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(ss.max_sales_price, 0) AS max_sales_price,
    COALESCE(ss.min_sales_price, 0) AS min_sales_price,
    rs.rank_order AS latest_rank
FROM item i
LEFT JOIN SalesSummary ss ON i.i_item_sk = ss.cs_item_sk
LEFT JOIN (
    SELECT * FROM RankedSales WHERE rank_order = 1
) rs ON i.i_item_sk = rs.cs_item_sk
WHERE 
    i_current_price >= (SELECT AVG(i_current_price) FROM item WHERE i_rec_start_date <= cast('2002-10-01' as date))
    OR EXISTS (
        SELECT 1 FROM store_sales ss
        WHERE ss.ss_item_sk = i.i_item_sk 
        AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2001)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2001)
    )
ORDER BY total_quantity DESC NULLS LAST, avg_sales_price DESC;