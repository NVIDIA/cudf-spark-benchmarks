
WITH CustomerDemographics AS (
    SELECT cd_demo_sk, 
           cd_gender, 
           cd_marital_status,
           cd_education_status,
           cd_purchase_estimate,
           cd_credit_rating,
           cd_dep_count,
           cd_dep_employed_count,
           cd_dep_college_count
    FROM customer_demographics 
    WHERE cd_purchase_estimate > 1000
),
CustomerAddresses AS (
    SELECT ca_address_sk,
           ca_city,
           ca_state,
           ca_zip
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
),
DateSales AS (
    SELECT d.d_date_sk,
           d.d_year,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_date_sk, d.d_year
),
Statistics AS (
    SELECT cd.cd_gender,
           ca.ca_city,
           ds.d_year,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
           MAX(ds.total_sales) AS max_sales
    FROM CustomerDemographics cd
    JOIN CustomerAddresses ca ON cd.cd_demo_sk = ca.ca_address_sk
    JOIN DateSales ds ON cd.cd_demo_sk = ds.d_date_sk
    GROUP BY cd.cd_gender, ca.ca_city, ds.d_year
)
SELECT cs.ca_city,
       cs.cd_gender,
       cs.d_year,
       cs.avg_purchase_estimate,
       cs.max_sales,
       CONCAT('City: ', cs.ca_city, ', Gender: ', cs.cd_gender, ', Year: ', CAST(cs.d_year AS STRING), 
              ', Avg Purchase: ', CAST(cs.avg_purchase_estimate AS STRING), 
              ', Max Sales: ', CAST(cs.max_sales AS STRING)) AS summary_info
FROM Statistics cs
ORDER BY cs.ca_city, cs.cd_gender, cs.d_year;
