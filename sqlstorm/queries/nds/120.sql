
WITH SalesData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        wd.d_year,
        wd.d_month_seq,
        SUM(ws.ws_sales_price * ws.ws_quantity) OVER (PARTITION BY c.c_customer_sk ORDER BY wd.d_year, wd.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as cumulative_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim wd ON ws.ws_sold_date_sk = wd.d_date_sk
    WHERE 
        wd.d_year >= 2021
), 
FilteredSales AS (
    SELECT 
        sd.c_customer_sk,
        sd.c_first_name,
        sd.c_last_name,
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        sd.cumulative_sales,
        RANK() OVER (PARTITION BY sd.c_customer_sk ORDER BY sd.cumulative_sales DESC) as rank
    FROM 
        SalesData sd
    WHERE 
        sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_category = 'Electronics')
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.cumulative_sales,
    COALESCE(r.r_reason_desc, 'No Reason') as return_reason
FROM 
    FilteredSales fs
LEFT JOIN 
    store_returns sr ON fs.ws_item_sk = sr.sr_item_sk AND fs.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE 
    fs.rank = 1
    AND fs.cumulative_sales > 500
ORDER BY 
    fs.cumulative_sales DESC;
