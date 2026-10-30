
WITH RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_item_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
StorePerformance AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_net_profit) AS avg_net_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ss_store_sk
),
HighPerformingStores AS (
    SELECT 
        sp.ss_store_sk,
        sp.total_sales,
        sp.avg_net_profit,
        RANK() OVER (ORDER BY sp.total_sales DESC) AS sales_rank
    FROM 
        StorePerformance sp
    WHERE 
        sp.total_sales > 10000
)
SELECT 
    cm.c_customer_sk,
    cm.cd_gender,
    cm.cd_marital_status,
    COALESCE(rs.total_sales, 0) AS recent_sales,
    COALESCE(rs.total_profit, 0) AS recent_profit,
    hps.total_sales AS store_sales,
    hps.avg_net_profit AS store_avg_profit
FROM 
    CustomerMetrics cm
LEFT JOIN 
    RecentSales rs ON cm.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    HighPerformingStores hps ON cm.c_customer_sk = hps.ss_store_sk
WHERE 
    (cm.cd_gender = 'M' OR cm.cd_marital_status = 'S') 
    AND (rs.total_sales IS NOT NULL OR hps.total_sales IS NOT NULL)
ORDER BY 
    cm.total_spent DESC;
