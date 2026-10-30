
WITH AddressMetrics AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        SUM(CASE WHEN ca_street_name LIKE '%Ave%' THEN 1 ELSE 0 END) AS ave_streets,
        AVG(CAST(ca_zip AS INTEGER)) AS avg_zip
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), GenderMetrics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), SalesMetrics AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_quantity) AS total_items_sold
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), CombinedMetrics AS (
    SELECT 
        a.ca_city, 
        a.ca_state, 
        a.total_addresses, 
        a.ave_streets, 
        a.avg_zip, 
        g.cd_gender, 
        g.total_customers, 
        g.avg_purchase_estimate, 
        g.total_dependents, 
        s.total_sales, 
        s.total_items_sold
    FROM 
        AddressMetrics a
    JOIN 
        GenderMetrics g ON a.ca_city = g.cd_gender
    JOIN 
        SalesMetrics s ON a.total_addresses = s.total_items_sold
)
SELECT 
    cm.ca_city, 
    cm.ca_state, 
    cm.total_addresses,
    cm.ave_streets,
    cm.avg_zip,
    cm.cd_gender,
    cm.total_customers,
    cm.avg_purchase_estimate,
    cm.total_dependents,
    cm.total_sales,
    cm.total_items_sold
FROM 
    CombinedMetrics cm
ORDER BY 
    cm.total_sales DESC, 
    cm.total_addresses DESC;
