
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        w.web_country = 'USA'
    GROUP BY 
        ws.ws_sold_date_sk
),
warehouse_data AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        w.w_country = 'USA'
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    sd.ws_sold_date_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.total_tax,
    sd.total_orders,
    wd.total_inventory,
    (sd.total_sales - sd.total_tax) AS net_sales
FROM 
    sales_data sd
JOIN 
    warehouse_data wd ON sd.ws_sold_date_sk = wd.inv_warehouse_sk
ORDER BY 
    sd.ws_sold_date_sk DESC;
