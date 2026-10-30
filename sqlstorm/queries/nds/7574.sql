
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons,
        d_year,
        d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2020
    GROUP BY 
        ws_item_sk, d_year, d_month_seq
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_coupons,
        sd.d_year,
        sd.d_month_seq,
        ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    it.i_item_id,
    it.i_item_desc,
    ts.total_quantity,
    ts.total_sales,
    ts.total_coupons,
    ts.d_year,
    ts.d_month_seq
FROM 
    TopSales ts
JOIN 
    item it ON ts.ws_item_sk = it.i_item_sk
JOIN 
    date_dim dd ON ts.d_year = dd.d_year AND ts.d_month_seq = dd.d_month_seq
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.d_year, ts.total_sales DESC;
