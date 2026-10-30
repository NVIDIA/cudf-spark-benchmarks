
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        w.w_warehouse_id,
        c.c_first_name,
        c.c_last_name,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND
        cd.cd_gender = 'F' AND
        ws.ws_sales_price > 50
)
SELECT 
    sd.w_warehouse_id,
    COUNT(DISTINCT sd.ws_item_sk) AS unique_item_count,
    SUM(sd.ws_quantity) AS total_quantity,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    SUM(sd.ws_ext_sales_price) AS total_sales_value,
    sd.c_first_name,
    sd.c_last_name,
    sd.d_date,
    sd.cd_gender,
    sd.cd_marital_status
FROM 
    SalesData sd
GROUP BY 
    sd.w_warehouse_id,
    sd.c_first_name,
    sd.c_last_name,
    sd.d_date,
    sd.cd_gender,
    sd.cd_marital_status
ORDER BY 
    total_sales_value DESC
LIMIT 100;
