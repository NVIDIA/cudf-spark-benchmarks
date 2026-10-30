
WITH SalesData AS (
    SELECT 
        ws.ws_web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_web_site_sk
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_sk,
        AVG(w.w_warehouse_sq_ft) AS avg_warehouse_size
    FROM 
        warehouse w
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    sd.ws_web_site_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.total_profit,
    wd.avg_warehouse_size
FROM 
    SalesData sd
JOIN 
    WarehouseData wd ON sd.ws_web_site_sk = wd.w_warehouse_sk
ORDER BY 
    sd.total_profit DESC
LIMIT 10;
