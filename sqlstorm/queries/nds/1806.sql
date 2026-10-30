
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(ws.ws_sales_price - ws.ws_ext_discount_amt, 0), ws.ws_sales_price) AS net_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY COALESCE(ws.ws_ext_tax, 0) DESC) AS tax_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.net_price,
        rs.ws_quantity,
        (rs.net_price * rs.ws_quantity) AS total_value
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
),
AggregateSales AS (
    SELECT 
        iv.inv_item_sk,
        SUM(COALESCE(hvs.total_value, 0)) AS total_sales_value,
        COUNT(hvs.ws_order_number) AS order_count
    FROM 
        inventory iv
    LEFT JOIN 
        HighValueSales hvs ON iv.inv_item_sk = hvs.ws_item_sk
    GROUP BY 
        iv.inv_item_sk
)
SELECT 
    ia.i_item_id,
    ia.i_product_name,
    aas.total_sales_value,
    aas.order_count,
    CASE 
        WHEN aas.total_sales_value > 10000 THEN 'High Value'
        WHEN aas.total_sales_value IS NULL THEN 'No Sales'
        ELSE 'Standard Value'
    END AS sales_category
FROM 
    item ia
LEFT JOIN 
    AggregateSales aas ON ia.i_item_sk = aas.inv_item_sk
WHERE 
    ia.i_current_price IS NOT NULL
ORDER BY 
    total_sales_value DESC NULLS LAST
LIMIT 100;
