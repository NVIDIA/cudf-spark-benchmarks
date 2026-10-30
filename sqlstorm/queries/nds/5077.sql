
WITH CustomerStats AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        ca_state
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        SUM(ws_net_profit) AS net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_fulfilled,
        SUM(ws_ext_sales_price) AS sales_generated
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
OverallStats AS (
    SELECT 
        cs.ca_state,
        cs.customer_count,
        cs.avg_purchase_estimate,
        cs.total_dependents,
        ss.d_year,
        ss.total_sales,
        ss.total_tax,
        ss.net_profit,
        ws.w_warehouse_id,
        ws.orders_fulfilled,
        ws.sales_generated
    FROM 
        CustomerStats cs
    JOIN 
        SalesStats ss ON ss.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
    JOIN 
        WarehouseStats ws ON ws.sales_generated > 100000
)
SELECT 
    os.ca_state,
    os.customer_count,
    os.avg_purchase_estimate,
    os.total_dependents,
    os.d_year,
    os.total_sales,
    os.total_tax,
    os.net_profit,
    os.w_warehouse_id,
    os.orders_fulfilled,
    os.sales_generated
FROM 
    OverallStats os
ORDER BY 
    os.total_sales DESC, os.customer_count ASC;
