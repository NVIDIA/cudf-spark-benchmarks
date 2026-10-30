
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2022 
        AND cd.cd_gender = 'F' 
        AND cd.cd_education_status = 'Masters'
    GROUP BY 
        ws.ws_item_sk
), TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ts.total_quantity,
    ts.total_sales
FROM 
    TopSales ts
JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
