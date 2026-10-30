
WITH RevenueData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_coupon_amt) AS total_coupons,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS orders_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c_customer_sk
),
TopItems AS (
    SELECT 
        rd.ws_item_sk,
        rd.total_sales,
        rd.total_coupons,
        cd.orders_count,
        cd.total_profit,
        ROW_NUMBER() OVER (ORDER BY rd.total_sales DESC) AS rank
    FROM 
        RevenueData rd
    JOIN 
        CustomerData cd ON rd.ws_item_sk = cd.c_customer_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_sales,
    ti.total_coupons,
    ti.orders_count,
    ti.total_profit
FROM 
    TopItems ti
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_sales DESC;
