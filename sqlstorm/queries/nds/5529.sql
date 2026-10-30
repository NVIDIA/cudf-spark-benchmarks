
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        SUM(ws_coupon_amt) AS total_discount 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31') 
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        sd.ws_item_sk, 
        sd.total_quantity_sold, 
        sd.total_sales, 
        sd.total_discount,
        it.i_item_desc,
        it.i_current_price
    FROM 
        SalesData sd
    JOIN 
        item it ON sd.ws_item_sk = it.i_item_sk
    ORDER BY 
        sd.total_sales DESC 
    LIMIT 10
)
SELECT 
    t.ws_item_sk,
    t.total_quantity_sold,
    t.total_sales,
    t.total_discount,
    t.i_item_desc,
    t.i_current_price,
    (t.total_sales - t.total_discount) AS net_sales
FROM 
    TopSales t
JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = t.ws_item_sk
    )
ORDER BY 
    net_sales DESC;
