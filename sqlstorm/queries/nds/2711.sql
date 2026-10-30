
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
Sales_Aggregate AS (
    SELECT 
        total_store_sales,
        total_web_sales,
        CASE 
            WHEN total_store_sales > total_web_sales THEN 'Store'
            WHEN total_store_sales < total_web_sales THEN 'Web'
            ELSE 'Equal'
        END AS preferred_channel
    FROM 
        Customer_Sales
),
Sales_Stats AS (
    SELECT 
        preferred_channel,
        COUNT(*) AS customer_count,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(total_web_sales) AS avg_web_sales,
        SUM(total_store_sales) AS total_sales_store,
        SUM(total_web_sales) AS total_sales_web
    FROM 
        Sales_Aggregate
    GROUP BY 
        preferred_channel
)
SELECT 
    ss.preferred_channel,
    ss.customer_count,
    ss.avg_store_sales,
    ss.avg_web_sales,
    ss.total_sales_store,
    ss.total_sales_web,
    CASE 
        WHEN ss.total_sales_store > ss.total_sales_web THEN 'Store Dominance'
        WHEN ss.total_sales_store < ss.total_sales_web THEN 'Web Dominance'
        ELSE 'Balanced Sales'
    END AS sales_trend
FROM 
    Sales_Stats ss
ORDER BY 
    ss.preferred_channel;
