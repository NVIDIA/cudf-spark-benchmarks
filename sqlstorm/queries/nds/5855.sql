
WITH CustomerGroups AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        warehouse AS w
    JOIN 
        inventory AS inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
FinalReport AS (
    SELECT 
        cg.cd_gender,
        cs.total_sales,
        cs.total_net_profit,
        ws.total_inventory
    FROM 
        CustomerGroups AS cg
    JOIN 
        SalesSummary AS cs ON 1=1
    JOIN 
        WarehouseStats AS ws ON 1=1
)
SELECT 
    cd_gender,
    total_sales,
    total_net_profit,
    total_inventory
FROM 
    FinalReport
ORDER BY 
    cd_gender;
