
WITH SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        cd.cd_gender,
        COALESCE(d.d_year, 0) AS sales_year,
        SM.sm_ship_mode_id,
        W.w_warehouse_id,
        CS.cs_sales_price
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        ship_mode SM ON ws.ws_ship_mode_sk = SM.sm_ship_mode_sk
    LEFT JOIN 
        warehouse W ON ws.ws_warehouse_sk = W.w_warehouse_sk
    LEFT JOIN 
        catalog_sales CS ON ws.ws_item_sk = CS.cs_item_sk AND ws.ws_order_number = CS.cs_order_number
    WHERE 
        COALESCE(ws.ws_sales_price, 0) > 0
    AND 
        (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
),
AggregatedSales AS (
    SELECT 
        sales_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_quantity * ws_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        SalesDetails
    GROUP BY 
        sales_year
)
SELECT 
    a.sales_year,
    a.total_orders,
    a.total_quantity,
    a.total_sales,
    a.avg_sales_price,
    RANK() OVER (ORDER BY a.total_sales DESC) AS sales_rank
FROM 
    AggregatedSales a
WHERE 
    a.total_sales > (SELECT AVG(total_sales) FROM AggregatedSales)
ORDER BY 
    a.total_sales DESC;
