
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rnk,
        COALESCE(SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk), 0) AS total_quantity,
        AVG(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS avg_payment
    FROM 
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    AND 
        (ws.ws_sold_date_sk BETWEEN 2459241 AND 2459247 
        OR ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023 AND d.d_moy IN (4, 5)))
),
TopSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_paid,
        rs.total_quantity,
        rs.avg_payment
    FROM 
        RankedSales rs
    WHERE 
        rs.rnk = 1
    AND 
        (rs.ws_net_paid > (SELECT AVG(ws2.ws_net_paid) FROM web_sales ws2 WHERE ws2.ws_item_sk = rs.ws_item_sk)
         OR rs.total_quantity > 100)
)

SELECT 
    t1.ws_order_number,
    t1.ws_item_sk,
    t1.ws_quantity,
    t1.ws_net_paid,
    COALESCE(SUM(t2.cr_return_quantity), 0) AS total_returns,
    MAX(CASE WHEN t2.cr_return_quantity IS NOT NULL THEN t2.cr_return_amount ELSE 0 END) AS max_return_amount,
    CASE WHEN AVG(t1.avg_payment) IS NULL THEN 'No Sales' ELSE 'Sales Existing' END AS sales_status
FROM 
    TopSales t1
LEFT JOIN 
    catalog_returns t2 ON t1.ws_order_number = t2.cr_order_number AND t1.ws_item_sk = t2.cr_item_sk
GROUP BY 
    t1.ws_order_number, t1.ws_item_sk, t1.ws_quantity, t1.ws_net_paid
HAVING 
    COUNT(t1.ws_quantity) > 10 
OR 
    SUM(CASE WHEN t1.ws_net_paid < 50 THEN 1 ELSE 0 END) > 5
ORDER BY 
    t1.ws_order_number DESC, t1.ws_item_sk;
