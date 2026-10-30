
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c_current_addr_sk) AS unique_addresses
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_net_profit,
        ss_store_sk,
        ss_sold_date_sk
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
WarehouseSales AS (
    SELECT 
        w_warehouse_sk,
        SUM(ws_net_paid_inc_tax) AS total_net_sales
    FROM 
        web_sales
    JOIN 
        warehouse ON ws_warehouse_sk = w_warehouse_sk
    GROUP BY 
        w_warehouse_sk
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.unique_addresses,
    ss.total_quantity,
    ss.total_sales,
    ss.total_net_profit,
    ws.total_net_sales,
    COUNT(DISTINCT ss.ss_store_sk) AS number_of_stores,
    MIN(w.w_warehouse_name) AS top_warehouse_by_sales
FROM 
    CustomerStats cs
JOIN 
    SalesStats ss ON cs.total_customers > 50
JOIN 
    WarehouseSales ws ON ws.total_net_sales > 10000
JOIN 
    warehouse w ON w.w_warehouse_sk = ws.w_warehouse_sk
GROUP BY 
    cs.cd_gender, cs.total_customers, cs.avg_purchase_estimate, cs.unique_addresses, ss.total_quantity, ss.total_sales, ss.total_net_profit, ws.total_net_sales
HAVING 
    SUM(ss.total_sales) > 50000
ORDER BY 
    cs.cd_gender;
