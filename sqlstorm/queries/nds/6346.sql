
WITH SalesData AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        inventory i ON ws.ws_item_sk = i.inv_item_sk
    JOIN 
        item it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year BETWEEN 2019 AND 2021 
        AND it.i_current_price > 50
    GROUP BY 
        d.d_year
),
GroupedData AS (
    SELECT 
        d_year,
        total_sales,
        total_discount,
        total_orders,
        avg_sales_price
    FROM 
        SalesData
)
SELECT 
    g.d_year,
    g.total_sales,
    g.total_discount,
    g.total_orders,
    g.avg_sales_price,
    (g.total_sales - g.total_discount) AS net_sales
FROM 
    GroupedData g
ORDER BY 
    g.d_year;
