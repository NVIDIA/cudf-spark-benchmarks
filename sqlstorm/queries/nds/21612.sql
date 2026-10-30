
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_sales_price - ws_ext_discount_amt AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) as sales_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.net_sales,
        COALESCE(NULLIF(rs.net_sales, 0), NULL) as safe_net_sales,
        CASE 
            WHEN SUBSTRING(i.i_item_desc, 1, 5) = 'Cheap' THEN 'Budget'
            WHEN SUBSTRING(i.i_item_desc, 1, 5) = 'Expen' THEN 'Premium'
            ELSE 'Standard'
        END AS price_category
    FROM RankedSales rs
    JOIN item i ON rs.ws_item_sk = i.i_item_sk
    WHERE rs.sales_rank <= 10
),
MaxSales AS (
    SELECT 
        price_category,
        MAX(net_sales) AS max_net_sales
    FROM FilteredSales
    GROUP BY price_category
),
SalesSummary AS (
    SELECT 
        fs.price_category,
        COUNT(*) AS total_orders,
        SUM(fs.ws_quantity) AS total_quantity,
        MAX(ms.max_net_sales) AS highest_sale
    FROM FilteredSales fs
    LEFT JOIN MaxSales ms ON fs.price_category = ms.price_category
    GROUP BY fs.price_category
)
SELECT 
    ss.price_category,
    ss.total_orders,
    ss.total_quantity,
    ss.highest_sale,
    CASE 
        WHEN ss.total_orders > 100 THEN 'High Volume'
        WHEN ss.total_orders BETWEEN 50 AND 100 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category,
    CASE 
        WHEN ss.highest_sale IS NULL THEN 'No Sales Recorded'
        ELSE 'Sales Present'
    END AS sales_record_status
FROM SalesSummary ss
WHERE ss.total_quantity > (
    SELECT AVG(total_quantity) 
    FROM SalesSummary
)
ORDER BY ss.total_orders DESC
LIMIT 5;
