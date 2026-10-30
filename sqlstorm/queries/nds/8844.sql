
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_returned_date_sk) AS return_days,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM 
        customer AS c
    LEFT JOIN 
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
WarehouseSales AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_sales_price) AS total_sales_price
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_warehouse_sk
), 
PromotionalStats AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales_with_discount
    FROM 
        promotion AS p
    JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    coalesce(crs.return_days, 0) AS return_days,
    coalesce(crs.total_return_quantity, 0) AS total_return_quantity,
    coalesce(crs.total_return_amt, 0) AS total_return_amt,
    ws.total_sales_quantity,
    ws.total_sales_price,
    ps.total_orders,
    ps.total_sales_with_discount
FROM 
    customer AS c
LEFT JOIN 
    CustomerReturnStats AS crs ON c.c_customer_sk = crs.c_customer_sk
LEFT JOIN 
    WarehouseSales AS ws ON ws.ws_warehouse_sk = c.c_current_addr_sk
LEFT JOIN 
    PromotionalStats AS ps ON ps.p_promo_sk = c.c_current_cdemo_sk
WHERE 
    c.c_preferred_cust_flag = 'Y'
ORDER BY 
    c.c_last_name, 
    c.c_first_name;
