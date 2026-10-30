
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CombinedSales AS (
    SELECT 
        cs.c_customer_sk,
        COALESCE(total_web_orders, 0) AS total_web_orders,
        COALESCE(total_web_profit, 0) AS total_web_profit,
        COALESCE(total_store_orders, 0) AS total_store_orders,
        COALESCE(total_store_profit, 0) AS total_store_profit
    FROM 
        CustomerSales cs
    FULL OUTER JOIN 
        StoreSales ss ON cs.c_customer_sk = ss.c_customer_sk
),
SalesAnalytics AS (
    SELECT 
        c.c_customer_sk,
        total_web_orders,
        total_web_profit,
        total_store_orders,
        total_store_profit,
        RANK() OVER (ORDER BY (total_web_profit + total_store_profit) DESC) AS sales_rank,
        ROW_NUMBER() OVER (PARTITION BY (CASE 
            WHEN total_web_profit > total_store_profit THEN 'Web' 
            ELSE 'Store' 
        END) ORDER BY (total_web_profit + total_store_profit) DESC) AS partition_rank
    FROM 
        CombinedSales c
)
SELECT 
    c.c_customer_id,
    sales_rank,
    partition_rank,
    total_web_orders,
    total_web_profit,
    total_store_orders,
    total_store_profit,
    CONCAT('Customer ID: ', c.c_customer_id, ' has made ', 
        COALESCE(total_web_orders, 0) + COALESCE(total_store_orders, 0), 
        ' total orders with a combined profit of $', 
        ROUND(total_web_profit + total_store_profit, 2)) AS sales_summary
FROM 
    SalesAnalytics a
JOIN 
    customer c ON a.c_customer_sk = c.c_customer_sk
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;
