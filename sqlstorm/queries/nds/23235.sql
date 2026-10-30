
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT cd.cd_demo_sk) AS demographic_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), 
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        w.w_warehouse_name,
        COALESCE(SUM(ss.ss_net_profit), 0) AS store_net_profit
    FROM 
        store s
    LEFT JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, w.w_warehouse_name
)
SELECT 
    cs.c_customer_sk,
    cs.gender,
    cs.avg_purchase_estimate,
    CASE 
        WHEN rs.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    si.store_net_profit,
    ROUND(si.store_net_profit / NULLIF((SELECT SUM(store_net_profit) FROM StoreInfo), 0), 2) AS profit_ratio
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    StoreInfo si ON si.s_store_sk = (SELECT s.s_store_sk 
                                       FROM store s 
                                       ORDER BY s.s_store_sk 
                                       LIMIT 1) 
WHERE 
    cs.demographic_count > 0
    AND cs.avg_purchase_estimate > 100
ORDER BY 
    cs.avg_purchase_estimate DESC, 
    sales_status ASC
LIMIT 100;
