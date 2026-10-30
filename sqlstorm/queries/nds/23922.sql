
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_sales,
        NTILE(4) OVER (ORDER BY total_sales DESC) AS sales_quartile
    FROM 
        CustomerSales c
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    CASE 
        WHEN cs.sales_quartile = 1 THEN 'Highest Sales'
        WHEN cs.sales_quartile = 2 THEN 'Upper-Middle Sales'
        WHEN cs.sales_quartile = 3 THEN 'Lower-Middle Sales'
        ELSE 'Lowest Sales'
    END AS sales_category,
    COALESCE(inv.inv_quantity_on_hand, 0) AS available_inventory,
    (SELECT COUNT(*) FROM store s WHERE s.s_country IS NOT NULL AND s.s_city IS NOT NULL) AS store_count,
    (SELECT SUM(ws_ext_sales_price) FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk) AS total_web_sales
FROM 
    AggregateSales cs
LEFT JOIN 
    inventory inv ON (cs.c_customer_sk % 100) = inv.inv_item_sk
WHERE 
    cs.total_sales IS NOT NULL
ORDER BY 
    available_inventory DESC, 
    cs.total_sales DESC
LIMIT 10;
