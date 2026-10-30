
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year IN (2022, 2023)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.purchase_category,
    SUM(sd.total_sales) AS total_sales,
    AVG(sd.total_sales) AS avg_sales,
    SUM(sd.total_tax) AS total_tax,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (
        SELECT ws.ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws.ws_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
    )
GROUP BY 
    cd.purchase_category
ORDER BY 
    total_sales DESC;
