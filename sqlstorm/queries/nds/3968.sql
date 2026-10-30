
WITH relevant_dates AS (
    SELECT d_date_sk, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_year IN (2021, 2022)
), 
sales_data AS (
    SELECT 
        w.w_warehouse_id, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        relevant_dates rd ON ws.ws_sold_date_sk = rd.d_date_sk
    GROUP BY 
        w.w_warehouse_id
),
return_data AS (
    SELECT
        w.w_warehouse_id,
        COUNT(cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    JOIN 
        warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN 
        relevant_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    GROUP BY 
        w.w_warehouse_id
),
sales_returns AS (
    SELECT 
        sd.w_warehouse_id AS warehouse_id,
        sd.total_sales,
        sd.order_count,
        sd.total_discount,
        COALESCE(rd.return_count, 0) AS return_count,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount
    FROM 
        sales_data sd
    LEFT JOIN 
        return_data rd ON sd.w_warehouse_id = rd.w_warehouse_id
)
SELECT 
    warehouse_id,
    total_sales,
    order_count,
    total_discount,
    return_count,
    total_return_amount,
    (total_sales - total_return_amount) AS net_sales,
    ROUND((total_discount / NULLIF(total_sales, 0)) * 100, 2) AS discount_percentage,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM 
    sales_returns
WHERE 
    (total_sales - total_return_amount) > 0
ORDER BY 
    total_sales DESC
LIMIT 10;
