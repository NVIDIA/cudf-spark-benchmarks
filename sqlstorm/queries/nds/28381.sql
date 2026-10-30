
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ProductSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_price
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_item_sk
),
SalesByGender AS (
    SELECT 
        ci.cd_gender,
        SUM(ps.total_sold) AS gender_sales,
        AVG(ps.avg_price) AS avg_price_per_item
    FROM 
        CustomerInfo AS ci
    JOIN 
        web_sales AS ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        ProductSales AS ps ON ws.ws_item_sk = ps.ws_item_sk
    GROUP BY 
        ci.cd_gender
)
SELECT 
    cd_gender,
    gender_sales,
    avg_price_per_item,
    RANK() OVER (ORDER BY gender_sales DESC) AS sales_rank
FROM 
    SalesByGender
ORDER BY 
    gender_sales DESC;
