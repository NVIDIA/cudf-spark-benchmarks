
WITH  Sales_CTE AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                              AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY cs_bill_customer_sk
    HAVING SUM(cs_net_profit) IS NOT NULL
),
Top_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
        sc.total_net_profit,
        sc.total_orders
    FROM customer c
    JOIN Sales_CTE sc ON c.c_customer_sk = sc.cs_bill_customer_sk
    WHERE sc.rank <= 10
),
Warehouse_Stats AS (
    SELECT 
        w.w_warehouse_id,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ss_item_sk) AS distinct_items_sold
    FROM warehouse w
    LEFT JOIN store s ON w.w_warehouse_sk = s.s_store_sk
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY w.w_warehouse_id
),
Inventory_Analysis AS (
    SELECT 
        i.i_item_id,
        MAX(i.i_current_price) AS max_price,
        MIN(i.i_current_price) AS min_price,
        COUNT(DISTINCT inv.inv_date_sk) AS days_in_stock
    FROM item i
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE inv.inv_quantity_on_hand < 50
    GROUP BY i.i_item_id
)
SELECT 
    tc.customer_full_name,
    tc.total_net_profit,
    tc.total_orders,
    ws.total_sales,
    wa.max_price,
    wa.min_price,
    wa.days_in_stock,
    CASE 
        WHEN tc.total_net_profit > 1000 THEN 'High Value'
        WHEN tc.total_net_profit > 0 AND tc.total_net_profit <= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM Top_Customers tc
JOIN Warehouse_Stats ws ON ws.total_sales = (SELECT MAX(total_sales) FROM Warehouse_Stats)
JOIN Inventory_Analysis wa ON wa.max_price IS NOT NULL 
WHERE wa.days_in_stock >= (SELECT AVG(days_in_stock) FROM Inventory_Analysis)
ORDER BY tc.total_net_profit DESC, ws.total_sales DESC, wa.max_price ASC
LIMIT 5 OFFSET 2;
