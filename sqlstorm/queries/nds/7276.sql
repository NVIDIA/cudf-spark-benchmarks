
WITH SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
), CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
), WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)

SELECT 
    sd.d_year,
    sd.total_quantity_sold,
    sd.total_sales,
    cd.cd_gender,
    cd.total_customers,
    cd.total_purchase_estimate,
    wd.w_warehouse_id,
    wd.unique_items,
    wd.total_net_paid
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON cd.total_customers > 100
JOIN 
    WarehouseData wd ON wd.total_net_paid > 10000
ORDER BY 
    sd.d_year, cd.cd_gender, wd.w_warehouse_id;
