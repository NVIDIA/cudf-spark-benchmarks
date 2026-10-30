
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
TopSellers AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sold,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rank <= 10
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
GenderStatistics AS (
    SELECT 
        cd.cd_gender,
        COUNT(cs.c_customer_sk) AS customer_count,
        SUM(cs.total_spent) AS total_spent
    FROM 
        CustomerStats cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ts.ws_item_sk,
    ts.total_sold,
    ts.total_profit,
    gs.cd_gender,
    gs.customer_count,
    gs.total_spent
FROM 
    TopSellers ts
LEFT JOIN 
    GenderStatistics gs ON gs.cd_gender = CASE 
                                              WHEN ts.total_profit > 0 THEN 'M'
                                              ELSE 'F' 
                                           END
ORDER BY 
    ts.total_profit DESC, 
    gs.total_spent DESC
