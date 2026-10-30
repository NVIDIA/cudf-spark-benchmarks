
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
    WHERE 
        sd.rn = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_sales,
    COALESCE(p.p_promo_name, 'No Promotion') AS promotion_name,
    CASE 
        WHEN ts.total_sales > 5000 THEN 'High Seller'
        WHEN ts.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Seller'
        ELSE 'Low Seller'
    END AS sales_category
FROM
    item i
LEFT JOIN 
    TopSales ts ON i.i_item_sk = ts.ws_item_sk
LEFT JOIN 
    promotion p ON p.p_item_sk = ts.ws_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
