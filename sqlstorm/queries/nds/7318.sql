
WITH RankedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220801 AND 20220831
    GROUP BY 
        ws.ws_bill_customer_sk, c.c_current_cdemo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.total_sales,
        r.order_count,
        r.ws_bill_customer_sk
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.order_count,
    ca.ca_city,
    ca.ca_state,
    i.i_item_desc,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM 
    TopCustomers tc
JOIN 
    customer_address ca ON tc.ws_bill_customer_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON tc.ws_bill_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY 
    tc.c_customer_id, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.total_sales, 
    tc.order_count, 
    ca.ca_city, 
    ca.ca_state, 
    i.i_item_desc
ORDER BY 
    tc.total_sales DESC
LIMIT 50;
