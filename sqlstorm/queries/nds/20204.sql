
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk DESC) AS order_rank,
        SUM(ws_quantity) OVER (PARTITION BY ws_bill_customer_sk) AS total_quantity,
        COALESCE(SUM(ws_net_profit) OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sold_date_sk), 0) AS cumulative_profit,
        ws_net_profit
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 100
),
AggregatedSales AS (
    SELECT 
        ws_bill_customer_sk,
        AVG(total_quantity) AS avg_quantity,
        MAX(cumulative_profit) AS max_profit,
        MIN(cumulative_profit) AS min_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        RankedSales
    WHERE 
        order_rank <= 5
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
    SUM(cs.cs_net_profit) AS total_catalog_profit,
    AVG(COALESCE(a.avg_quantity, 0)) AS avg_quantity_per_customer,
    MAX(a.max_profit) AS highest_customer_profit,
    MIN(a.min_profit) AS lowest_customer_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    AggregatedSales a ON c.c_customer_sk = a.ws_bill_customer_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (c.c_birth_month IS NULL OR c.c_birth_month > 6)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(cs.cs_net_profit) IS NOT NULL 
    AND COUNT(DISTINCT cs.cs_order_number) > 10
ORDER BY 
    total_catalog_profit DESC
LIMIT 100;
