
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        sum(ws.ws_quantity) AS total_quantity,
        sum(ws.ws_net_paid_inc_tax) AS total_net_sales,
        sum(ws.ws_ext_discount_amt) AS total_discount,
        i.i_category,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, i.i_category, d.d_year
),
TopSales AS (
    SELECT 
        i_category,
        d_year,
        rank() OVER(PARTITION BY d_year ORDER BY total_net_sales DESC) AS rank,
        total_quantity,
        total_net_sales,
        total_discount
    FROM 
        SalesData
)
SELECT 
    i_category,
    d_year,
    total_quantity,
    total_net_sales,
    total_discount
FROM 
    TopSales
WHERE 
    rank <= 5
ORDER BY 
    d_year, total_net_sales DESC;
