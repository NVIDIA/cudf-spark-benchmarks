
WITH SalesData AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        SUM(ws.ws_ext_tax) AS total_tax, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023 
        AND cd.cd_gender = 'F' 
        AND i.i_category = 'Electronics'
    GROUP BY 
        d.d_year
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        inventory inv ON ws.ws_item_sk = inv.inv_item_sk 
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
DemographicSummary AS (
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
    s.d_year,
    s.total_sales,
    s.total_tax,
    s.total_orders,
    w.warehouse_sales,
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate
FROM 
    SalesData s
JOIN 
    WarehouseSales w ON s.total_sales IS NOT NULL
JOIN 
    DemographicSummary d ON d.customer_count IS NOT NULL
ORDER BY 
    s.d_year DESC;
