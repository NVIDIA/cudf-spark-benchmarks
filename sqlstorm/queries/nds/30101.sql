
WITH  CategorySales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
),
TopCategories AS (
    SELECT 
        i.i_item_id,
        cs.total_sales,
        i.i_category
    FROM 
        item i
    JOIN 
        CategorySales cs ON i.i_item_sk = cs.cs_item_sk
    WHERE 
        cs.sales_rank <= 10
),
CustomerAddressGroups AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    tc.i_item_id,
    tc.total_sales,
    cag.ca_state,
    cag.customer_count,
    cag.avg_vehicle_count,
    CASE 
        WHEN cag.customer_count IS NULL THEN 'No Customers'
        ELSE 'Customers Present'
    END AS customer_status
FROM 
    TopCategories tc
FULL OUTER JOIN 
    CustomerAddressGroups cag ON tc.i_category = cag.ca_state
WHERE 
    (tc.total_sales > 10000 OR cag.customer_count > 0)
ORDER BY 
    tc.total_sales DESC,
    cag.customer_count DESC
LIMIT 50;
