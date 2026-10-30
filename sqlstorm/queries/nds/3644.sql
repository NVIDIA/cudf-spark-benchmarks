
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_net_profit > 0
        AND d.d_year = 2023
),
ProfitableItems AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 1000
)
SELECT 
    p.ws_item_sk, 
    p.total_profit,
    r.ca_city, 
    COUNT(r.ws_order_number) AS num_orders, 
    AVG(r.ws_net_profit) AS avg_net_profit
FROM 
    ProfitableItems p
JOIN 
    RankedSales r ON p.ws_item_sk = r.ws_item_sk 
WHERE 
    r.profit_rank <= 10
GROUP BY 
    p.ws_item_sk, p.total_profit, r.ca_city
ORDER BY 
    p.total_profit DESC, num_orders DESC
LIMIT 50;
