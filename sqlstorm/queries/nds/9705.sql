WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 100 
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        *
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10 
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        web_sales ws
    JOIN 
        CustomerDemographics cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        ws.ws_item_sk IN (SELECT ws_item_sk FROM TopItems)
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    COUNT(*) AS number_of_sales,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_net_paid) AS total_revenue
FROM 
    SalesDetails sd
GROUP BY 
    sd.cd_gender, sd.cd_marital_status, sd.cd_education_status
ORDER BY 
    total_revenue DESC
LIMIT 50;