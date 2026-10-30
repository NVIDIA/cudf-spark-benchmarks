WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT ca_address_id) AS unique_addresses, 
        COUNT(*) AS total_addresses 
    FROM 
        customer_address 
    GROUP BY 
        ca_state
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents 
    FROM 
        customer_demographics 
    GROUP BY 
        cd_gender
), 
SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws_ext_sales_price) AS total_sales 
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk 
    GROUP BY 
        w.w_warehouse_name
), 
CombinedData AS (
    SELECT 
        ac.ca_state,
        ac.unique_addresses,
        ac.total_addresses,
        ds.cd_gender,
        ds.avg_purchase_estimate,
        ds.total_dependents,
        sd.w_warehouse_name,
        sd.total_sales
    FROM 
        AddressCounts ac
    JOIN 
        DemographicStats ds ON ac.ca_state = 'CA'  
    JOIN 
        SalesData sd ON sd.total_sales > 10000  
)
SELECT 
    ca_state,
    unique_addresses,
    total_addresses,
    cd_gender,
    avg_purchase_estimate,
    total_dependents,
    w_warehouse_name,
    total_sales
FROM 
    CombinedData
ORDER BY 
    unique_addresses DESC, 
    avg_purchase_estimate DESC;