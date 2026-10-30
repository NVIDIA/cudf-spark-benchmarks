
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
Sales_With_Gender AS (
    SELECT 
        cd.cd_gender,
        SUM(total_web_sales) AS total_web_sales_by_gender,
        SUM(total_catalog_sales) AS total_catalog_sales_by_gender,
        SUM(total_store_sales) AS total_store_sales_by_gender,
        SUM(web_order_count) AS total_web_orders_by_gender,
        SUM(catalog_order_count) AS total_catalog_orders_by_gender,
        SUM(store_order_count) AS total_store_orders_by_gender
    FROM 
        Customer_Sales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
Sales_By_Education AS (
    SELECT 
        cd.cd_education_status,
        SUM(Total_Web_Sales_By_Gender) AS Total_Web_Sales,
        SUM(Total_Catalog_Sales_By_Gender) AS Total_Catalog_Sales,
        SUM(Total_Store_Sales_By_Gender) AS Total_Store_Sales
    FROM 
        Sales_With_Gender sg
    JOIN 
        customer_demographics cd ON sg.cd_gender = cd.cd_gender
    GROUP BY 
        cd.cd_education_status
)

SELECT 
    ed.cd_education_status,
    SUM(total_web_sales) AS total_sales_web,
    SUM(total_catalog_sales) AS total_sales_catalog,
    SUM(total_store_sales) AS total_sales_store,
    AVG(total_web_sales) AS avg_web_sales,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales
FROM 
    Sales_By_Education ed
GROUP BY 
    ed.cd_education_status
ORDER BY 
    total_sales_web DESC, total_sales_catalog DESC, total_sales_store DESC;
