
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
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
        dd.d_year = 2023 
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales,
        sd.avg_net_paid,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity_sold,
    rs.total_sales,
    rs.avg_net_paid,
    rs.sales_rank
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
