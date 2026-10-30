
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-10-31')
    GROUP BY 
        c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cs.total_net_profit) AS avg_net_profit,
        AVG(cs.order_count) AS avg_order_count,
        AVG(cs.unique_items_sold) AS avg_unique_items
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.avg_net_profit,
    da.avg_order_count,
    da.avg_unique_items,
    DENSE_RANK() OVER (ORDER BY da.avg_net_profit DESC) AS rank_by_profit
FROM 
    DemographicAnalysis da
WHERE 
    da.avg_order_count > 5
ORDER BY 
    da.avg_net_profit DESC;
