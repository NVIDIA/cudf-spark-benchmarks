
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_per_order
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        i.i_current_price > (
            SELECT 
                AVG(i2.i_current_price) 
            FROM 
                item i2
            WHERE 
                i2.i_class_id IN (
                    SELECT DISTINCT i_class_id 
                    FROM item
                    WHERE i_category = 'Beverages'
                )
        )
    GROUP BY 
        ws.ws_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sd.total_quantity_sold,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_net_paid_per_order
FROM 
    SalesData sd
JOIN 
    item i ON sd.ws_item_sk = i.i_item_sk
ORDER BY 
    sd.total_net_profit DESC
LIMIT 10;
