
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales 
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
DemographicsSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics cd ON c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
WarehouseStatistics AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv_item_sk) AS distinct_items
    FROM 
        inventory
    JOIN 
        warehouse w ON inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ss.d_year,
    ss.total_sales,
    ss.order_count,
    ss.avg_net_profit,
    ds.cd_gender,
    ds.customer_count,
    ds.avg_purchase_estimate,
    ws.w_warehouse_id,
    ws.total_inventory,
    ws.distinct_items
FROM 
    SalesSummary ss
CROSS JOIN 
    DemographicsSummary ds
CROSS JOIN 
    WarehouseStatistics ws
ORDER BY 
    ss.d_year DESC, 
    ds.cd_gender;
