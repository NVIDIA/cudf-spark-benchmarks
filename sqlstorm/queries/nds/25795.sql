
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ws.ws_bill_cdemo_sk
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_bill_cdemo_sk
),
SalesWithDemographics AS (
    SELECT 
        cs.ws_item_sk,
        cs.total_quantity,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        ItemSales cs
    JOIN 
        customer_demographics cd ON cs.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_sales) AS total_revenue
FROM 
    SalesWithDemographics
GROUP BY 
    cd_gender, cd_marital_status, cd_education_status, ca_city, ca_state
ORDER BY 
    total_revenue DESC;
