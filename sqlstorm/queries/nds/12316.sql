WITH sales_summary AS (
    SELECT 
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2457122 AND 2457485 
)
SELECT 
    total_sales,
    total_transactions,
    avg_net_profit
FROM 
    sales_summary;