
WITH  SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, 'Customer' AS level, SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, 'Demographics' AS level, SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY c.c_customer_sk, c.c_customer_id
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, 'Warehouse' AS level, SUM(ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),

AggregateSales AS (
    SELECT 
        c_customer_id,
        SUM(total_sales) AS grand_total_sales,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM SalesHierarchy
    GROUP BY c_customer_id
),

FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN grand_total_sales > 5000 THEN 'High'
            WHEN grand_total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM AggregateSales
)

SELECT 
    fs.c_customer_id,
    fs.grand_total_sales,
    fs.sales_category,
    COALESCE(ROUND((SELECT AVG(grand_total_sales) FROM FilteredSales WHERE sales_category = fs.sales_category), 2), 0) AS avg_sales_in_category
FROM FilteredSales fs
ORDER BY fs.grand_total_sales DESC
LIMIT 10;

