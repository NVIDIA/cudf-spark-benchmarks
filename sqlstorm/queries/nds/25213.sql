
WITH CustomerDetails AS (
  SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_purchases
  FROM 
    customer c
  JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
  WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M'
),
HighValueCustomers AS (
  SELECT 
    DISTINCT full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY cd_purchase_estimate DESC) AS city_rank
  FROM 
    CustomerDetails
  WHERE 
    total_purchases > 0
)
SELECT 
  full_name,
  ca_city,
  ca_state,
  cd_gender,
  cd_marital_status,
  cd_purchase_estimate
FROM 
  HighValueCustomers
WHERE 
  city_rank <= 5
ORDER BY 
  ca_city, 
  cd_purchase_estimate DESC;
