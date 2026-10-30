
WITH  sales_summary AS (
    SELECT 
        ss_store_sk,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_revenue,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
top_stores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        total_sales,
        total_revenue,
        total_profit,
        rank
    FROM 
        sales_summary
        JOIN store ON sales_summary.ss_store_sk = store.s_store_sk
    WHERE 
        rank <= 5
)
SELECT 
    t.s_store_name,
    t.total_sales,
    t.total_revenue,
    t.total_profit,
    COALESCE((SELECT AVG(cd_purchase_estimate) 
               FROM customer_demographics 
               WHERE cd_demo_sk IN (SELECT DISTINCT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'New York'))), 0) AS avg_purchase_estimate,
    CASE 
        WHEN t.total_profit > 5000 THEN 'High Profit'
        WHEN t.total_profit BETWEEN 2000 AND 5000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    top_stores t
LEFT JOIN 
    ship_mode sm ON t.total_sales <= (SELECT COUNT(*) FROM ship_mode) AND sm.sm_ship_mode_sk = 1
ORDER BY 
    t.total_revenue DESC;
