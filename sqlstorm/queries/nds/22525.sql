WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(cs.cs_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
FilteredSales AS (
    SELECT 
        c.c_customer_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_profit DESC) as order_rank
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.order_count,
    cs.avg_net_profit,
    fs.cs_order_number,
    fs.cs_quantity,
    fs.cs_net_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    FilteredSales fs ON cs.c_customer_sk = fs.c_customer_sk AND fs.order_rank <= 3
WHERE 
    cs.total_quantity > (SELECT AVG(total_quantity) FROM CustomerStats) 
    AND cs.order_count IS NOT NULL
ORDER BY 
    cs.avg_net_profit DESC NULLS LAST;