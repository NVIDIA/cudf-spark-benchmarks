
WITH  sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_city
    HAVING 
        SUM(ss.ss_net_paid) IS NOT NULL

    UNION ALL

    SELECT 
        wh.w_warehouse_sk,
        wh.w_warehouse_name,
        wh.w_city,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY wh.w_warehouse_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM 
        warehouse wh
    LEFT JOIN 
        inventory i ON wh.w_warehouse_sk = i.inv_warehouse_sk
    LEFT JOIN 
        store_sales ss ON i.inv_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        wh.w_warehouse_sk, wh.w_warehouse_name, wh.w_city
    HAVING 
        SUM(ss.ss_net_paid) IS NOT NULL
)

SELECT 
    hierarchy.s_store_name AS store_name,
    hierarchy.s_city AS store_city,
    COALESCE(SUM(hierarchy.total_sales), 0) AS total_sales,
    COUNT(DISTINCT CASE WHEN hierarchy.rank = 1 THEN hierarchy.s_store_sk END) AS top_selling_stores
FROM 
    sales_hierarchy hierarchy
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = hierarchy.s_store_sk
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_gender IS NULL)
    AND cd.cd_marital_status = 'M'
GROUP BY 
    hierarchy.s_store_name, hierarchy.s_city
ORDER BY 
    total_sales DESC;
