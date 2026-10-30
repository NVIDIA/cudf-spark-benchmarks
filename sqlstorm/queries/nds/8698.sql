
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_item_sk
), 
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), 
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_revenue,
    sd.avg_sales_price,
    cd.order_count AS customer_order_count,
    id.total_inventory
FROM 
    SalesData sd
LEFT JOIN 
    CustomerData cd ON sd.ws_item_sk = cd.c_customer_sk
LEFT JOIN 
    InventoryData id ON sd.ws_item_sk = id.inv_item_sk
WHERE 
    sd.total_revenue > 10000
ORDER BY 
    sd.total_revenue DESC
LIMIT 100;
