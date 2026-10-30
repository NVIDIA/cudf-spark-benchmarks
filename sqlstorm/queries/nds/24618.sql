
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk, ws_sold_date_sk ORDER BY ws_quantity DESC) AS rank_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
        )
),
AggregatedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        RankedSales
    WHERE 
        rank_profit = 1
    GROUP BY 
        ws_item_sk
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_customer_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year < 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ProfitableCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.total_customer_profit,
        CASE WHEN ABS(cp.total_customer_profit - avg_profit.avg_profit) > 100 THEN 1 ELSE 0 END AS is_profitable
    FROM 
        CustomerProfits cp
    CROSS JOIN 
        (SELECT 
            AVG(total_profit) AS avg_profit 
        FROM 
            AggregatedSales) avg_profit
)

SELECT 
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    COUNT(DISTINCT pc.c_customer_sk) AS high_profit_customers,
    AVG(pc.total_customer_profit) AS avg_profit_of_profitable_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    ProfitableCustomers pc ON c.c_customer_sk = pc.c_customer_sk
WHERE 
    (ca.ca_state IS NOT NULL AND ca.ca_state IN ('CA', 'TX', 'NY'))
    OR (pc.is_profitable = 1 AND pc.total_customer_profit >= 500)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT pc.c_customer_sk) > 10
ORDER BY 
    avg_profit_of_profitable_customers DESC;
