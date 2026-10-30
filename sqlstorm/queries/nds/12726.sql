
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_desc, 
    sd.total_quantity, 
    sd.total_sales
FROM 
    item i 
JOIN 
    sales_data sd ON i.i_item_sk = sd.ws_item_sk
ORDER BY 
    sd.total_sales DESC 
LIMIT 10;
