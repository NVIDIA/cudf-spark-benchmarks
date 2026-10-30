
WITH AddressStats AS (
    SELECT ca_county, 
           SUM(LENGTH(ca_street_name)) AS total_street_name_length,
           COUNT(DISTINCT ca_address_sk) AS address_count,
           AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM customer_address
    GROUP BY ca_county
), CustomerDemographics AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           SUBSTRING(cd.cd_education_status, 1, 3) AS short_education_status
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > 1000
), WarehouseStats AS (
    SELECT w.w_city,
           COUNT(w.w_warehouse_sk) AS total_warehouses,
           AVG(w.w_warehouse_sq_ft) AS avg_warehouse_size
    FROM warehouse w
    GROUP BY w.w_city
), WebSalesSummary AS (
    SELECT ws.ws_web_site_sk,
           SUM(ws.ws_sales_price) AS total_sales_value,
           COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_web_site_sk
)
SELECT a.ca_county, 
       a.total_street_name_length, 
       a.address_count, 
       a.avg_street_name_length, 
       cd.cd_gender, 
       cd.short_education_status, 
       w.w_city, 
       w.total_warehouses, 
       w.avg_warehouse_size, 
       ws.ws_web_site_sk, 
       ws.total_sales_value, 
       ws.total_orders
FROM AddressStats a
JOIN CustomerDemographics cd ON a.address_count > 5
JOIN WarehouseStats w ON a.ca_county = w.w_city
JOIN WebSalesSummary ws ON w.total_warehouses > 10
ORDER BY a.total_street_name_length DESC, ws.total_sales_value DESC;
