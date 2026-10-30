
WITH  sales_data AS (
    SELECT 
        s.ss_item_sk, 
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        s.ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_item_sk,
        sd.total_sales,
        sd.total_transactions,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank <= 10
),
inventory_check AS (
    SELECT 
        i.inv_item_sk, 
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    WHERE 
        i.inv_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        i.inv_item_sk
)
SELECT 
    t.ss_item_sk,
    t.total_sales,
    t.total_transactions,
    COALESCE(ic.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN t.total_sales > 1000 THEN 'High'
        WHEN t.total_sales > 500 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    top_sales t
LEFT JOIN 
    inventory_check ic ON t.ss_item_sk = ic.inv_item_sk
ORDER BY 
    t.total_sales DESC;
