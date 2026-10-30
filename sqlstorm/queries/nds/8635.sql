
WITH customer_data AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('PhD', 'Masters')
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
), sales_data AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2430
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cd.c_customer_id, 
    cd.c_first_name, 
    cd.c_last_name, 
    sd.w_warehouse_id, 
    cd.total_sales, 
    sd.total_sales AS warehouse_sales
FROM 
    customer_data cd
JOIN 
    sales_data sd ON cd.total_sales > sd.total_sales
ORDER BY 
    cd.total_sales DESC, 
    sd.total_sales ASC
LIMIT 100;
