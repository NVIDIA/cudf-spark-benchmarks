WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        CTE_WEBSALES.total_web_sales,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_ext_sales_price DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN (
        SELECT 
            ws.ws_item_sk,
            SUM(ws.ws_ext_sales_price) AS total_web_sales
        FROM 
            web_sales ws
        GROUP BY 
            ws.ws_item_sk
    ) CTE_WEBSALES ON cs.cs_item_sk = CTE_WEBSALES.ws_item_sk
    WHERE 
        cs.cs_sold_date_sk BETWEEN 2459973 AND 2459979 
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    SUM(RankedSales.cs_quantity) AS total_sales_quantity,
    SUM(RankedSales.cs_ext_sales_price) AS total_sales_value
FROM 
    RankedSales
JOIN 
    item ON RankedSales.cs_item_sk = item.i_item_sk
WHERE 
    RankedSales.sales_rank = 1
GROUP BY 
    item.i_item_id,
    item.i_item_desc
ORDER BY 
    total_sales_value DESC
LIMIT 10;