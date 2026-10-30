
WITH RecursiveCustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_ext_sales_price), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
MaxSales AS (
    SELECT 
        MAX(total_sales) AS max_sales
    FROM 
        RecursiveCustomerSales
)
SELECT 
    rcs.c_customer_sk,
    rcs.c_first_name,
    rcs.c_last_name,
    rcs.total_sales,
    CASE 
        WHEN rcs.total_sales = 0 THEN 'No Sales'
        WHEN rcs.total_sales = (SELECT max_sales FROM MaxSales) THEN 'Top Seller'
        ELSE 'Regular Customer'
    END AS customer_status,
    CASE 
        WHEN rcs.total_sales IS NULL THEN 'Unknown'
        ELSE CAST(rcs.total_sales AS CHAR(20))
    END AS sales_amount,
    (SELECT COUNT(*) FROM customer_address ca WHERE ca.ca_city = 'New York') AS total_addresses_in_ny,
    (SELECT COUNT(DISTINCT cs.cs_item_sk) FROM catalog_sales cs WHERE cs.cs_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_type = 'Standard')) AS total_standard_items
FROM 
    RecursiveCustomerSales rcs
WHERE 
    rcs.rank <= 10
ORDER BY 
    rcs.total_sales DESC;
