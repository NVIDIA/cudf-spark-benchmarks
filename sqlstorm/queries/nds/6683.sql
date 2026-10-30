
WITH CustomerDemographics AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           SUM(ws.ws_net_profit) AS total_profit
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
AddressDetails AS (
    SELECT ca.ca_state, COUNT(DISTINCT c.c_customer_sk) AS address_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_state
),
SalesData AS (
    SELECT d.d_year, d.d_month_seq, SUM(ws.ws_sales_price) AS monthly_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
CombinedData AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
           ad.ca_state, 
           sd.d_year AS year, 
           sd.d_month_seq AS month, 
           COUNT(*) AS demographic_count, 
           SUM(sd.monthly_sales) AS total_sales,
           SUM(cd.total_profit) AS total_profit
    FROM CustomerDemographics cd
    JOIN AddressDetails ad ON cd.customer_count > 0
    JOIN SalesData sd ON cd.cd_demo_sk > 0
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, 
             ad.ca_state, sd.d_year, sd.d_month_seq
)
SELECT * FROM CombinedData
ORDER BY year DESC, month DESC, total_sales DESC;
