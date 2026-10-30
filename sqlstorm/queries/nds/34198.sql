
WITH  SalesCTE AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(ss1.ss_sold_date_sk) - 30 FROM store_sales ss1)
    GROUP BY 
        ss.ss_sold_date_sk,
        ss.ss_item_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        SUM(s.total_sales) AS total_sales_last_30_days,
        COUNT(s.ss_item_sk) AS unique_items_sold
    FROM 
        customer c
    JOIN 
        SalesCTE s ON c.c_customer_sk = s.ss_item_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_birth_year
),
HighSpenders AS (
    SELECT 
        s.c_customer_id,
        s.total_sales_last_30_days,
        CASE 
            WHEN s.total_sales_last_30_days > 1000 THEN 'High'
            WHEN s.total_sales_last_30_days BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM 
        SalesSummary s
    WHERE 
        s.unique_items_sold > 5
)
SELECT 
    h.c_customer_id,
    h.total_sales_last_30_days,
    h.spending_category,
    d.d_day_name,
    w.w_warehouse_name
FROM 
    HighSpenders h
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d2.d_date_sk) FROM date_dim d2)
LEFT JOIN 
    warehouse w ON w.w_warehouse_sk = (
        SELECT inv.inv_warehouse_sk 
        FROM inventory inv 
        WHERE inv.inv_item_sk IN (SELECT DISTINCT s.ss_item_sk FROM store_sales s)
        GROUP BY inv.inv_warehouse_sk 
        ORDER BY SUM(inv.inv_quantity_on_hand) DESC 
        LIMIT 1
    )
WHERE 
    h.spending_category = 'High'
ORDER BY 
    h.total_sales_last_30_days DESC;
