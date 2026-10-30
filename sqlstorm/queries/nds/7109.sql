
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        w.w_warehouse_name,
        wb.wp_type,
        dd.d_year,
        dd.d_month_seq
    FROM 
        web_sales AS ws
    JOIN 
        customer AS ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
    JOIN 
        web_page AS wb ON ws.ws_web_page_sk = wb.wp_web_page_sk
    JOIN 
        warehouse AS w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND ws.ws_sales_price > 50
),
AggregatedSales AS (
    SELECT 
        sd.c_first_name,
        sd.c_last_name,
        sd.c_email_address,
        sd.w_warehouse_name,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(sd.ws_order_number) AS total_orders,
        sd.d_month_seq
    FROM 
        SalesData AS sd
    GROUP BY 
        sd.c_first_name, 
        sd.c_last_name, 
        sd.c_email_address, 
        sd.w_warehouse_name,
        sd.d_month_seq
)
SELECT 
    asd.c_first_name,
    asd.c_last_name,
    asd.c_email_address,
    asd.w_warehouse_name,
    asd.total_sales,
    asd.total_orders,
    (SELECT COUNT(DISTINCT w2.w_warehouse_sk) FROM warehouse w2) AS total_warehouses
FROM 
    AggregatedSales AS asd
ORDER BY 
    asd.total_sales DESC
LIMIT 10;
