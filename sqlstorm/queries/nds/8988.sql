
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk, d.d_year, d.d_month_seq
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cd.c_customer_sk,
        SUM(sd.total_sales) AS total_spent
    FROM 
        SalesData sd
    JOIN 
        web_sales ws ON sd.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    GROUP BY 
        cd.c_customer_sk
    HAVING 
        SUM(sd.total_sales) > 10000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cv.total_spent
FROM 
    HighValueCustomers cv
JOIN 
    customer c ON cv.c_customer_sk = c.c_customer_sk
ORDER BY 
    cv.total_spent DESC
LIMIT 10;
