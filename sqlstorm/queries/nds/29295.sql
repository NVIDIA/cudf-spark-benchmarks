
WITH AddressCounty AS (
    SELECT ca_county, 
           COUNT(DISTINCT ca_address_sk) AS address_count,
           SUM(CASE WHEN ca_state = 'CA' THEN 1 ELSE 0 END) AS cali_address_count
    FROM customer_address
    GROUP BY ca_county
),
DemographicStats AS (
    SELECT cd_gender, 
           COUNT(*) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate,
           SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesStatistics AS (
    SELECT 
           w.w_warehouse_name,
           SUM(ws.ws_net_paid) AS total_sales,
           SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_name
),
FinalReport AS (
    SELECT ac.ca_county,
           ac.address_count,
           ac.cali_address_count,
           ds.cd_gender,
           ds.customer_count,
           ds.avg_purchase_estimate,
           ds.married_count,
           ss.w_warehouse_name AS warehouse_name,
           ss.total_sales,
           ss.total_discount
    FROM AddressCounty ac
    JOIN DemographicStats ds ON ds.customer_count > 100
    JOIN SalesStatistics ss ON ss.total_sales > 1000
)
SELECT 
    fs.ca_county,
    fs.address_count,
    fs.cali_address_count,
    fs.cd_gender,
    fs.customer_count,
    fs.avg_purchase_estimate,
    fs.married_count,
    fs.warehouse_name,
    fs.total_sales,
    fs.total_discount
FROM FinalReport fs
ORDER BY fs.total_sales DESC, fs.address_count ASC;
