
WITH SalesData AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq IN (1, 2, 3) 
    GROUP BY 
        w.w_warehouse_id
),
CustomerInfo AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    sd.w_warehouse_id,
    sd.total_profit,
    sd.order_count,
    sd.avg_order_value,
    ci.cd_gender,
    ci.customer_count,
    ci.avg_purchase_estimate
FROM 
    SalesData sd
JOIN 
    CustomerInfo ci ON sd.total_profit > 10000
ORDER BY 
    sd.total_profit DESC, 
    ci.customer_count DESC
LIMIT 10;
