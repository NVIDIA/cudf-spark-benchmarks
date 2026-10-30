
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ts.total_sales, 0) AS total_sales,
    CASE 
        WHEN ts.total_sales IS NULL THEN 'No sales'
        WHEN ts.total_sales > 1000 THEN 'High Sales'
        ELSE 'Moderate Sales'
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    TotalSales ts ON i.i_item_sk = ts.ws_item_sk
WHERE 
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sales_price > 0
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
