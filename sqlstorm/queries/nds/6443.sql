
WITH RankedSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY w.w_warehouse_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_sk
),
TopWarehouses AS (
    SELECT 
        w_warehouse_id, 
        total_quantity, 
        total_profit 
    FROM 
        RankedSales 
    WHERE 
        profit_rank <= 5
)
SELECT 
    tw.w_warehouse_id,
    tw.total_quantity,
    tw.total_profit,
    w.w_city,
    w.w_state,
    (SELECT COUNT(*) FROM store s WHERE s.s_country = 'USA' AND s.s_state = w.w_state) AS store_count
FROM 
    TopWarehouses tw
JOIN 
    warehouse w ON tw.w_warehouse_id = w.w_warehouse_id
ORDER BY 
    tw.total_profit DESC;
