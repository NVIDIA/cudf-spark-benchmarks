
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales <= 3
    GROUP BY 
        rs.ws_item_sk
),
SalesAnalysis AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ts.total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MIN(ws.ws_sales_price) AS min_price,
        MAX(ws.ws_sales_price) AS max_price,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 'No Orders'
            ELSE CAST(MAX(ws.ws_sales_price) AS VARCHAR(10))
        END AS price_analysis
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        TotalSales ts ON i.i_item_sk = ts.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc, ts.total_sales
)
SELECT 
    sales.i_item_id,
    sales.i_item_desc,
    sales.total_sales,
    sales.order_count,
    sales.min_price,
    sales.max_price,
    SA.price_analysis
FROM 
    SalesAnalysis sales
LEFT JOIN 
    (SELECT DISTINCT *, 
            ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS item_rank
     FROM SalesAnalysis) SA ON sales.i_item_id = SA.i_item_id
WHERE 
    sales.total_sales IS NOT NULL
    AND (SA.item_rank <= 10 OR sales.order_count = 0)
ORDER BY 
    sales.total_sales DESC;
