
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelors', 'Masters')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
),
SalesPerformance AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        pi.i_item_id,
        pi.i_item_desc,
        cs.total_sales,
        pi.total_quantity_sold
    FROM 
        CustomerData cs
    JOIN 
        PopularItems pi ON cs.total_sales > 1000
)
SELECT 
    sp.c_customer_id,
    sp.c_first_name,
    sp.c_last_name,
    sp.i_item_id,
    sp.i_item_desc,
    sp.total_sales,
    sp.total_quantity_sold
FROM 
    SalesPerformance sp
ORDER BY 
    sp.total_sales DESC, sp.total_quantity_sold DESC;
