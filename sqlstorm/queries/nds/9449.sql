
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 AND 
        cd.cd_gender = 'F' AND 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity,
        sd.total_sales,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        SalesData sd
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.total_profit,
    w.w_warehouse_name,
    sm.sm_type AS shipping_method,
    dd.d_month_seq AS month
FROM 
    TopItems ti
JOIN 
    inventory inv ON ti.ws_item_sk = inv.inv_item_sk
JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN 
    ship_mode sm ON inv.inv_item_sk = sm.sm_ship_mode_sk
JOIN 
    date_dim dd ON inv.inv_date_sk = dd.d_date_sk
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    ti.total_profit DESC;
