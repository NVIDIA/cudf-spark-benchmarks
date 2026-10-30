
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        w.w_warehouse_name,
        d.d_month_seq,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        w.w_warehouse_name, 
        d.d_month_seq, 
        d.d_year
),
MaxSales AS (
    SELECT 
        warehouse_name,
        d_year,
        d_month_seq,
        MAX(total_sales) AS max_sales
    FROM 
        (SELECT 
            w.w_warehouse_name AS warehouse_name,
            d.d_year,
            d.d_month_seq,
            SUM(ws.ws_sales_price) AS total_sales
        FROM 
            web_sales ws
        JOIN 
            warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN 
            date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY 
            w.w_warehouse_name, 
            d.d_year, 
            d.d_month_seq) AS InnerSales
    GROUP BY 
        warehouse_name, d_year, d_month_seq
)
SELECT 
    sd.w_warehouse_name AS warehouse_name,
    sd.d_year,
    sd.d_month_seq,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.total_tax,
    sd.total_orders
FROM 
    SalesData sd
JOIN 
    MaxSales ms ON sd.w_warehouse_name = ms.warehouse_name 
                AND sd.d_year = ms.d_year 
                AND sd.d_month_seq = ms.d_month_seq 
                AND sd.total_sales = ms.max_sales
ORDER BY 
    sd.d_year DESC, sd.d_month_seq DESC, sd.w_warehouse_name;
