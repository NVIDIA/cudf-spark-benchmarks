
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank,
        (ws_sales_price * ws_quantity) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_sales_price,
        SUM(rs.total_sales) AS overall_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        rs.ws_item_sk, rs.ws_sales_price
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(ib.ib_income_band_sk, -1) AS income_band_sk
    FROM 
        item i
    LEFT JOIN 
        household_demographics hd ON i.i_item_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    id.i_item_desc,
    ts.overall_sales,
    ts.ws_sales_price,
    CASE 
        WHEN ts.overall_sales > 10000 THEN 'High Seller'
        WHEN ts.overall_sales BETWEEN 5000 AND 10000 THEN 'Moderate Seller'
        ELSE 'Low Seller'
    END AS seller_category,
    CONCAT('Income Band: ', 
           COALESCE(CAST(id.ib_lower_bound AS STRING), 'N/A'), 
           ' - ', 
           COALESCE(CAST(id.ib_upper_bound AS STRING), 'N/A')) AS income_range,
    NULLIF(ts.ws_sales_price, 0) AS adjusted_price
FROM 
    TopSales ts
JOIN 
    ItemDetails id ON ts.ws_item_sk = id.i_item_sk
WHERE 
    id.i_item_desc IS NOT NULL
ORDER BY 
    ts.overall_sales DESC
LIMIT 10 OFFSET 0;
