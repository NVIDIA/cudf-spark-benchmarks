
WITH BestSellingItems AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2458806 AND 2459138  
    GROUP BY 
        ws_item_sk
    ORDER BY 
        total_sales DESC
    LIMIT 10
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 500
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        BestSellingItems bsi ON ws.ws_item_sk = bsi.ws_item_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
    HAVING 
        SUM(ws.ws_sales_price) > 1000
),
FinalResults AS (
    SELECT 
        cp.c_customer_sk, 
        cp.c_first_name, 
        cp.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        CustomerPurchases cp
    JOIN 
        CustomerDemographics cd ON cp.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    f.*, 
    COUNT(ws.ws_order_number) AS total_orders
FROM 
    FinalResults f
LEFT JOIN 
    web_sales ws ON f.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    f.c_customer_sk, 
    f.c_first_name, 
    f.c_last_name, 
    f.cd_gender, 
    f.cd_marital_status
ORDER BY 
    total_orders DESC, 
    f.c_last_name;
