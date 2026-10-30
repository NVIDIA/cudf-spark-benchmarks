
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rnk
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        cs.cs_item_sk
),
TopItems AS (
    SELECT 
        rs.cs_item_sk,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk <= 5
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.total_quantity,
    ti.total_profit
FROM 
    TopItems ti
JOIN 
    store_sales ss ON ti.cs_item_sk = ss.ss_item_sk
JOIN 
    CustomerInfo ci ON ss.ss_customer_sk = ci.c_customer_sk
WHERE 
    ti.total_profit > 5000
ORDER BY 
    ti.total_profit DESC;
