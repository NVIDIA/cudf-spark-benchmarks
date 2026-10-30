
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_quantity) AS avg_quantity_per_order
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_net_profit) AS avg_net_profit_per_demo,
        SUM(cs.total_orders) AS total_orders_per_demo
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
StatewiseProfit AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_net_profit) AS state_net_profit,
        COUNT(DISTINCT cs.c_customer_sk) AS unique_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    s.ca_state,
    d.avg_net_profit_per_demo,
    s.state_net_profit,
    s.unique_customers
FROM 
    DemographicAnalysis d
JOIN 
    StatewiseProfit s ON s.unique_customers > 0
ORDER BY 
    s.state_net_profit DESC, d.avg_net_profit_per_demo DESC
LIMIT 10;
