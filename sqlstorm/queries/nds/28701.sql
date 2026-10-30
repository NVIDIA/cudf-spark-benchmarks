
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_sk,
        CONCAT(rc.c_first_name, ' ', rc.c_last_name) AS full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    JOIN 
        customer_demographics cd ON rc.c_customer_sk = cd.cd_demo_sk
    WHERE 
        rc.rank <= 5
),
SalesStatistics AS (
    SELECT 
        fc.full_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_sales_price) AS avg_sale_price
    FROM 
        web_sales ws
    JOIN 
        FilteredCustomers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    GROUP BY 
        fc.full_name
)
SELECT 
    fs.full_name,
    fs.total_orders,
    fs.total_sales,
    fs.avg_sale_price,
    CASE 
        WHEN fs.total_sales > 10000 THEN 'High Value'
        WHEN fs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    SalesStatistics fs
ORDER BY 
    fs.total_sales DESC;
