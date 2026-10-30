
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 
        AND cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_desc,
    sd.total_quantity,
    sd.total_sales,
    sd.avg_profit,
    ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS rank
FROM 
    sales_data sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
WHERE 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
