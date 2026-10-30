
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND cd.cd_gender = 'F'
        AND i.i_brand LIKE 'Brand%'
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    d.d_year,
    sd.total_quantity_sold,
    sd.total_net_paid,
    sd.average_sales_price
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
JOIN 
    date_dim d ON i.i_rec_start_date IS NOT NULL
GROUP BY 
    i.i_item_id,
    d.d_year,
    sd.total_quantity_sold,
    sd.total_net_paid,
    sd.average_sales_price
ORDER BY 
    sd.total_net_paid DESC
LIMIT 10;
