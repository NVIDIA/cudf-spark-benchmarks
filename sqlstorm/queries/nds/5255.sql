
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
)
SELECT 
    sa.ss_store_sk,
    sa.total_quantity,
    sa.total_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    sa.profit_rank
FROM 
    RankedSales sa
JOIN 
    CustomerDemographics cd ON sa.ss_store_sk = cd.cd_demo_sk
WHERE 
    sa.profit_rank <= 10
ORDER BY 
    sa.total_profit DESC, cd.customer_count DESC;
