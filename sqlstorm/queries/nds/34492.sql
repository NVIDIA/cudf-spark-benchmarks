
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
CustomerStatistics AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
IncomeBands AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        household_demographics hd
    JOIN 
        CustomerStatistics cs ON hd.hd_demo_sk = cs.c_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ca.ca_state,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(cs.total_orders) AS avg_orders,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerStatistics cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    IncomeBands ib ON cs.total_spent BETWEEN ib.avg_spent * 0.9 AND ib.avg_spent * 1.1
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 50
ORDER BY 
    rank
LIMIT 10;
