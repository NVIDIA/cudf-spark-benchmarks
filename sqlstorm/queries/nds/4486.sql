
WITH SalesData AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        w.w_warehouse_name,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND ws_sales_price > 0
), DiscountedSales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_ext_sales_price) AS total_sales,
        SUM(sd.ws_ext_discount_amt) AS total_discounts,
        COUNT(sd.ws_quantity) AS total_items
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_order_number
), RankedSales AS (
    SELECT
        ds.ws_order_number,
        ds.total_sales,
        ds.total_discounts,
        ds.total_items,
        RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
    FROM 
        DiscountedSales ds
)
SELECT 
    s.ws_order_number,
    s.total_sales,
    s.total_discounts,
    CASE 
        WHEN s.total_sales IS NULL THEN 'No Sales'
        WHEN s.total_discounts > 0 THEN CONCAT('Discount Applied: ', s.total_discounts)
        ELSE 'Full Price'
    END AS discount_status,
    w.w_warehouse_name,
    d.d_date
FROM 
    RankedSales s
LEFT JOIN 
    (SELECT DISTINCT ws_order_number, ws_warehouse_sk FROM web_sales) ws ON ws.ws_order_number = s.ws_order_number
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN 
    (SELECT DISTINCT ws_order_number, ws_sold_date_sk FROM web_sales) ws_date ON ws_date.ws_order_number = s.ws_order_number
LEFT JOIN 
    date_dim d ON d.d_date_sk = ws_date.ws_sold_date_sk
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.total_sales DESC;
