
WITH TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
SalesCounts AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS catalog_sales,
        COUNT(DISTINCT cs_order_number) AS catalog_order_count
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
ReturnsData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CombinedSales AS (
    SELECT 
        i.i_item_sk,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(sc.catalog_sales, 0) AS catalog_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(ts.order_count, 0) + COALESCE(sc.catalog_order_count, 0)) AS total_order_count
    FROM 
        item i
    LEFT JOIN 
        TotalSales ts ON i.i_item_sk = ts.ws_item_sk
    LEFT JOIN 
        SalesCounts sc ON i.i_item_sk = sc.cs_item_sk
    LEFT JOIN 
        ReturnsData rd ON i.i_item_sk = rd.sr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.catalog_sales,
    cs.total_returns,
    cs.total_order_count
FROM 
    customer c
JOIN 
    CombinedSales cs ON cs.total_order_count > 0
WHERE 
    cs.total_sales > 100 AND 
    c.c_birth_year BETWEEN 1980 AND 1990
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
