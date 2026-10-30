
WITH  daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date
), 
demographic_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
inventory_status AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) = 0 THEN 'Out of Stock'
            WHEN SUM(inv.inv_quantity_on_hand) BETWEEN 1 AND 10 THEN 'Low Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ds.d_date,
    ds.total_sales,
    ds.order_count,
    ds.total_sales / NULLIF(ds.order_count, 0) AS avg_order_value,
    ds.total_sales * COALESCE(SUM(CASE WHEN ds.total_sales > 1000 THEN 0.05 ELSE 0 END) OVER(), 0) AS discount_applied,
    ds.total_sales - ((ds.total_sales * COALESCE(SUM(CASE WHEN ds.total_sales > 1000 THEN 0.05 ELSE 0 END) OVER(), 0))) AS net_sales,
    ds.total_sales * 0.8 AS estimated_profit,
    ds.total_sales * COALESCE(MAX(CASE WHEN ds.order_count < 5 THEN 0.1 ELSE 0 END) OVER(), 0) AS potential_profit_loss,
    ds.total_sales + COALESCE(MAX(ds.total_sales) OVER (PARTITION BY ds.order_count), 0) AS adjusted_sales,
    CASE 
        WHEN ds.d_date IN (SELECT d.d_date FROM date_dim d WHERE d.d_dow IN (1, 2, 3, 4, 5)) THEN TRUE 
        ELSE FALSE 
    END AS weekday_sales,
    (SELECT 
        COUNT(*) 
     FROM 
        demographic_summary ds 
     WHERE 
        ds.customer_count > 100 AND ds.cd_gender = 'M') AS high_men_customers,
    (SELECT 
        COUNT(*) 
     FROM 
        inventory_status i 
     WHERE 
        i.stock_status = 'Out of Stock' 
     GROUP BY 
        i.stock_status) AS total_out_of_stock,
    (SELECT 
        COUNT(*) 
     FROM 
        demographic_summary ds 
     WHERE 
        ds.customer_count < 20 OR ds.avg_purchase_estimate IS NULL) AS low_activity_customers
FROM 
    daily_sales ds
GROUP BY 
    ds.d_date, ds.total_sales, ds.order_count
ORDER BY 
    ds.d_date DESC;
