
WITH SalesAnalysis AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN ss.ss_customer_sk END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN ss.ss_customer_sk END) AS male_customers
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        s.s_store_id
),
WarehousePerformance AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ss.ss_item_sk) AS items_sold,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        w.w_warehouse_id
),
FinalAnalysis AS (
    SELECT 
        sa.s_store_id,
        sa.total_net_profit,
        sa.avg_sales_price,
        sa.total_transactions,
        wp.w_warehouse_id,
        wp.items_sold,
        wp.total_quantity_sold,
        wp.total_profit,
        (sa.total_net_profit + wp.total_profit) AS combined_net_profit
    FROM 
        SalesAnalysis sa
    JOIN 
        WarehousePerformance wp ON sa.s_store_id = SUBSTRING(wp.w_warehouse_id, 1, 16)
)
SELECT 
    * 
FROM 
    FinalAnalysis
ORDER BY 
    combined_net_profit DESC
LIMIT 10;
