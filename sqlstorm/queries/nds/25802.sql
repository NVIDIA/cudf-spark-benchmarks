
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        web.web_name,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_site web ON c.c_customer_sk = web.web_site_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
ReturnDetails AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.full_address,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesDetails s ON cd.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    ReturnDetails r ON cd.c_customer_sk = r.wr_returning_customer_sk
ORDER BY 
    net_sales DESC
LIMIT 100;
