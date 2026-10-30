
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_discount,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS dense_rank_sales
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank = 1
)
SELECT 
    COALESCE(i.i_item_id, 'Unknown') AS item_id,
    COALESCE(s.total_quantity, 0) AS total_quantity_sold,
    COALESCE(s.total_sales, 0.00) AS total_sales_amount,
    COALESCE(s.total_discount, 0.00) AS total_discount_amount,
    CASE 
        WHEN s.total_sales > 5000 THEN 'High'
        WHEN s.total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_performance
FROM 
    TopSales s
LEFT JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    s.dense_rank_sales <= 10
ORDER BY 
    s.total_sales DESC;
