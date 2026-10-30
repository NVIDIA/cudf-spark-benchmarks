
WITH SalesSummary AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459000 AND 2459030 
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopPerformers AS (
    SELECT 
        customer_id,
        cd_gender,
        cd_marital_status,
        total_net_profit,
        total_orders,
        total_quantity_sold,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesSummary
)
SELECT 
    customer_id,
    cd_gender,
    cd_marital_status,
    total_net_profit,
    total_orders,
    total_quantity_sold
FROM 
    TopPerformers
WHERE 
    profit_rank <= 10 
ORDER BY 
    cd_gender, total_net_profit DESC;
