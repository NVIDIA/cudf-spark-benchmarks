
WITH SalesData AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS number_of_orders,
        AVG(ws.ws_sales_price) AS average_order_value,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    sd.c_customer_id,
    sd.total_sales,
    sd.number_of_orders,
    sd.average_order_value,
    sd.unique_items_sold,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.cd_dep_count
FROM 
    SalesData sd
JOIN 
    CustomerDemographics cd ON sd.c_customer_id = cd.c_customer_id
WHERE 
    sd.total_sales > 1000 
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
