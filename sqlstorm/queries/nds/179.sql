
WITH RankedSales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sales_price DESC) AS price_rank
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        rs.cs_order_number,
        rs.cs_item_sk,
        rs.cs_sales_price,
        rs.cs_quantity
    FROM RankedSales rs
    WHERE rs.price_rank <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_quantity_sold,
        CASE 
            WHEN i.i_current_price IS NULL THEN 'No Price'
            WHEN i.i_current_price < 20 THEN 'Low'
            WHEN i.i_current_price >= 20 AND i.i_current_price < 50 THEN 'Medium'
            ELSE 'High'
        END AS pricing_band
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_current_price
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.total_quantity_sold,
    id.pricing_band,
    ts.cs_order_number,
    ts.cs_sales_price
FROM ItemDetails id
JOIN TopSales ts ON id.i_item_sk = ts.cs_item_sk
WHERE id.total_quantity_sold IS NOT NULL
ORDER BY id.i_current_price DESC, ts.cs_sales_price ASC
LIMIT 100;
