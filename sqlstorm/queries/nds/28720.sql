
WITH AddressDetails AS (
  SELECT 
    ca.ca_address_sk,
    CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country
  FROM 
    customer_address ca
  WHERE 
    ca.ca_country = 'USA'
),
CustomerDetails AS (
  SELECT 
    c.c_customer_sk,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status
  FROM 
    customer c
  JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
  WHERE 
    cd.cd_marital_status IN ('M', 'S')
),
SalesDetails AS (
  SELECT 
    ws.ws_bill_customer_sk,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count
  FROM 
    web_sales ws
  GROUP BY 
    ws.ws_bill_customer_sk
),
FinalReport AS (
  SELECT 
    cd.full_name,
    ad.full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
  FROM 
    CustomerDetails cd
  JOIN 
    AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
  LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
  full_name,
  full_address,
  cd_gender,
  cd_marital_status,
  cd_education_status,
  total_sales,
  order_count
FROM 
  FinalReport
ORDER BY 
  total_sales DESC, order_count DESC
LIMIT 100;
