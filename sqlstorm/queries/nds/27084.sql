
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address 
    LEFT JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY 
        ca_address_sk, ca_street_number, ca_street_name, ca_street_type, ca_city, ca_state
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_dep_count) AS avg_dependencies,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        d.d_year,
        SUM(COALESCE(ws_net_profit, 0)) AS total_profit,
        SUM(COALESCE(ws_quantity, 0)) AS total_sold
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
WarehouseDetails AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        AVG(inv_quantity_on_hand) AS avg_inventory
    FROM 
        warehouse w
    JOIN 
        inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, w.w_warehouse_name
)

SELECT 
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.customer_count,
    ds.cd_gender,
    ds.total_customers,
    ds.avg_dependencies,
    ds.total_purchase_estimate,
    ss.d_year,
    ss.total_profit,
    ss.total_sold,
    wd.w_warehouse_name,
    wd.avg_inventory
FROM 
    AddressDetails ad
JOIN 
    DemographicStats ds ON ad.customer_count > 0
JOIN 
    SalesSummary ss ON ss.total_profit > 10000
JOIN 
    WarehouseDetails wd ON wd.avg_inventory > 50
ORDER BY 
    ad.customer_count DESC, ss.total_profit DESC;
