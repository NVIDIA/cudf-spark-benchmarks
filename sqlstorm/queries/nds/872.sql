
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        w.w_warehouse_name,
        d.d_date,
        ROW_NUMBER() OVER (PARTITION BY i.i_category, cd.cd_gender ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023 
        AND ws.ws_net_paid > 1000
)

SELECT 
    sds.i_brand,
    sds.i_category,
    sds.cd_gender,
    AVG(sds.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT sds.ws_order_number) AS total_orders,
    SUM(sds.ws_quantity) AS total_quantity
FROM 
    SalesData sds
WHERE 
    sds.rn <= 10
GROUP BY 
    sds.i_brand, 
    sds.i_category, 
    sds.cd_gender
ORDER BY 
    avg_net_profit DESC
LIMIT 50;
