
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1950 AND 1975
    GROUP BY 
        c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_net_profit) AS total_marital_net_profit
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status 
),
BestPerformers AS (
    SELECT 
        d.cd_gender,
        d.cd_marital_status,
        AVG(d.total_marital_net_profit) AS avg_net_profit
    FROM 
        Demographics d
    GROUP BY 
        d.cd_gender, d.cd_marital_status
)
SELECT 
    bp.cd_gender,
    bp.cd_marital_status,
    bp.avg_net_profit 
FROM 
    BestPerformers bp
WHERE 
    bp.avg_net_profit = (SELECT MAX(avg_net_profit) FROM BestPerformers)
ORDER BY 
    bp.cd_gender, bp.cd_marital_status;
