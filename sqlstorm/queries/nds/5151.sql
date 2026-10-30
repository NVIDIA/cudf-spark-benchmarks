
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        d.d_date,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_sold_date_sk,
        d.d_date,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        w.w_warehouse_name
), RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        total_sales,
        d_date,
        c_customer_id,
        ca_city,
        w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY total_sales ORDER BY d_date DESC) AS rn
    FROM 
        SalesData
)
SELECT 
    rs.ws_order_number,
    rs.ws_item_sk,
    rs.total_sales,
    rs.d_date,
    rs.c_customer_id,
    rs.ca_city,
    rs.w_warehouse_name
FROM 
    RankedSales rs
WHERE 
    rs.rn = 1
ORDER BY 
    rs.total_sales DESC
LIMIT 50;
