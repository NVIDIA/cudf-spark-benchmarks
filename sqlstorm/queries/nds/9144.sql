
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451002 AND 2451008  
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_quantity,
        cs.total_profit,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.hd_income_band_sk,
        RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        CustomerSales cs
)
SELECT 
    cs.cd_gender,
    cs.cd_marital_status,
    COUNT(*) AS customer_count,
    AVG(cs.total_quantity) AS avg_quantity,
    SUM(cs.total_profit) AS total_profit,
    MAX(cs.total_profit) AS max_profit
FROM 
    RankedSales cs
WHERE 
    cs.profit_rank <= 10  
GROUP BY 
    cs.cd_gender, cs.cd_marital_status
ORDER BY 
    cs.cd_gender, cs.cd_marital_status;
