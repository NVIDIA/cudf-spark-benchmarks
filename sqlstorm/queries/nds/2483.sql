
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
TopStores AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        r.total_quantity,
        r.total_net_profit
    FROM 
        RankedSales r
    JOIN 
        store s ON r.ss_store_sk = s.s_store_sk
    WHERE 
        r.store_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
)
SELECT 
    ts.s_store_id,
    ts.s_store_name,
    ts.total_quantity,
    ts.total_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    COALESCE((SELECT AVG(ss_ext_sales_price) 
               FROM store_sales 
               WHERE ss_item_sk IN (SELECT ss_item_sk FROM RankedSales)) , 0) AS avg_sales_price,
    CASE 
        WHEN ts.total_net_profit > 1000 THEN 'High Profit'
        WHEN ts.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopStores ts
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IN (
        SELECT 
            sr_cdemo_sk 
        FROM 
            store_returns 
        WHERE 
            sr_store_sk IN (SELECT ss_store_sk FROM store_sales)
    )
ORDER BY 
    ts.total_net_profit DESC;
