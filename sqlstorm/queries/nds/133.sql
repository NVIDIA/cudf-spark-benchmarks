
WITH SalesData AS (
    SELECT 
        s.s_store_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk, ws.ws_sold_date_sk
),
TopStores AS (
    SELECT 
        s_store_sk,
        total_sales,
        order_count
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
),
NullSales AS (
    SELECT 
        s.s_store_sk,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(ts.order_count, 0) AS order_count
    FROM 
        store s
    LEFT JOIN 
        TopStores ts ON s.s_store_sk = ts.s_store_sk
)
SELECT 
    s.s_store_sk,
    s.s_store_name,
    n.total_sales,
    n.order_count,
    d.d_year,
    SUM(CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 1 ELSE 0 END) AS null_ship_modes
FROM 
    store_sales ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    web_sales ws ON ss.ss_item_sk = ws.ws_item_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN 
    NullSales n ON s.s_store_sk = n.s_store_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    s.s_store_sk, s.s_store_name, n.total_sales, n.order_count, d.d_year
HAVING 
    SUM(ss.ss_sales_price) > 10000
ORDER BY 
    n.total_sales DESC;
