
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'M' AND 
        ca.ca_state = 'CA'
    GROUP BY 
        ws.ws_item_sk
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS customer_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
), TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        cs.customer_orders,
        cs.total_profit
    FROM 
        SalesData sd
    JOIN 
        CustomerStats cs ON sd.ws_item_sk = cs.c_customer_sk
    ORDER BY 
        sd.total_sales DESC
    LIMIT 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.customer_orders,
    ti.total_profit
FROM 
    TopItems ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price > 100 AND 
    i.i_brand LIKE '%Premium%'
ORDER BY 
    ti.total_profit DESC;
