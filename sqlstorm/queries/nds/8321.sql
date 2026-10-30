WITH CustomerMetrics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459591 AND 2459597  
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
TopStores AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_profit) AS store_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2459591 AND 2459597  
    GROUP BY 
        s.s_store_id
    ORDER BY 
        store_profit DESC
    LIMIT 10
)
SELECT 
    cm.cd_gender,
    cm.cd_marital_status,
    cm.total_sales,
    cm.customer_count,
    cm.avg_purchase_estimate,
    ts.s_store_id,
    ts.store_profit
FROM 
    CustomerMetrics cm
JOIN 
    TopStores ts ON cm.total_sales > 10000  
ORDER BY 
    cm.total_sales DESC, ts.store_profit DESC;