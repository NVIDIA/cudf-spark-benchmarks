
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND ib.ib_income_band_sk IN (1, 2, 3)
    GROUP BY 
        ws.ws_item_sk, d.d_year, d.d_month_seq
),
TopSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.total_orders,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    t.total_orders,
    t.sales_rank,
    i.i_item_desc,
    i.i_current_price,
    i.i_brand
FROM 
    TopSales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
