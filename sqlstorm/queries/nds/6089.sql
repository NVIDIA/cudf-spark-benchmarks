
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        i.i_item_desc,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451910 AND 2451970
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    SUM(sd.ws_net_paid) AS total_sales,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    COUNT(sd.ws_item_sk) AS item_count
FROM 
    sales_data sd
GROUP BY 
    sd.cd_gender, sd.cd_marital_status
ORDER BY 
    total_sales DESC;
