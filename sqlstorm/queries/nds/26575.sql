
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT_WS(', ', ca_street_number, ca_street_name, ca_street_type) AS Full_Street,
        CONCAT_WS(' ', ca_city, ca_county, ca_state, ca_zip, ca_country) AS Full_Location
    FROM 
        customer_address
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(SUM(ws.ws_quantity), 0) AS Total_Quantities,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS Total_Sales
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesSummary AS (
    SELECT 
        cs.ss_customer_sk as ca_address_sk,
        ai.Full_Street,
        ai.Full_Location,
        SUM(cs.ss_quantity) AS Store_Total_Quantities,
        SUM(cs.ss_ext_sales_price) AS Store_Total_Sales
    FROM 
        store_sales cs
        JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk
        JOIN AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
    GROUP BY 
        cs.ss_customer_sk, ai.Full_Street, ai.Full_Location
)
SELECT 
    cs.Full_Name,
    cs.cd_gender,
    cs.Total_Quantities,
    cs.Total_Sales,
    ss.Store_Total_Quantities,
    ss.Store_Total_Sales
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.ca_address_sk
ORDER BY 
    cs.Total_Sales DESC, cs.Total_Quantities DESC;
