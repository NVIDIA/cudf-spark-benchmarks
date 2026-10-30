WITH  SalesData AS (
    SELECT 
        cs_order_number,
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(cs_item_sk) AS item_count,
        cast('2002-10-01' as date) AS sales_date
    FROM catalog_sales
    GROUP BY cs_order_number, cs_item_sk
    UNION ALL
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_item_sk) AS item_count,
        cast('2002-10-01' as date) AS sales_date
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk
),
AggregateData AS (
    SELECT 
        s.cs_order_number,
        s.cs_item_sk,
        s.total_sales,
        s.item_count,
        d.d_year,
        d.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData s
    JOIN date_dim d ON s.sales_date = d.d_date
    WHERE s.total_sales IS NOT NULL
),
TopSalesData AS (
    SELECT 
        a.cs_order_number,
        a.cs_item_sk,
        a.total_sales,
        a.item_count
    FROM AggregateData a
    WHERE a.sales_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    a.cs_order_number,
    a.cs_item_sk,
    a.total_sales,
    COALESCE(sm.sm_carrier, 'Standard') AS shipping_mode,
    w.w_warehouse_name,
    CASE 
        WHEN a.total_sales > 1000 THEN 'High Value'
        WHEN a.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_value
FROM TopSalesData a
JOIN customer c ON c.c_customer_sk = a.cs_order_number
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = a.cs_item_sk
INNER JOIN warehouse w ON w.w_warehouse_sk = a.cs_item_sk
WHERE w.w_country IS NULL OR w.w_country = 'USA'
ORDER BY a.total_sales DESC, c.c_last_name, c.c_first_name;