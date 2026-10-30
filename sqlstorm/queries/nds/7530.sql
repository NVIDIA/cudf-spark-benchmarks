
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
popular_items AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity DESC
    LIMIT 10
),
customer_demographic AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
sales_analysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cd.cd_gender,
        cd.cd_education_status,
        pi.total_quantity
    FROM 
        customer_sales cs
    JOIN 
        customer_demographic cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN 
        popular_items pi ON cs.c_customer_sk = pi.ws_item_sk
)
SELECT 
    sales_analysis.c_customer_sk,
    sales_analysis.total_sales,
    sales_analysis.cd_gender,
    sales_analysis.cd_education_status,
    SUM(sales_analysis.total_quantity) AS total_popular_items_sold
FROM 
    sales_analysis
GROUP BY 
    sales_analysis.c_customer_sk, 
    sales_analysis.total_sales, 
    sales_analysis.cd_gender, 
    sales_analysis.cd_education_status
ORDER BY 
    total_popular_items_sold DESC;
