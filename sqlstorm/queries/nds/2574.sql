
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = DATE '2002-10-01')
),
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(rs.ws_sales_price * rs.ws_quantity, 0)) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.order_count,
    tc.sales_rank,
    (SELECT 
         COUNT(DISTINCT c.c_customer_id) 
     FROM 
         customer c 
     WHERE 
         c.c_current_addr_sk IS NOT NULL AND c.c_birth_year = 1985) AS num_customers_born_in_1985,
    (SELECT 
         SUM(ss.ss_net_profit) 
     FROM 
         store_sales ss 
     WHERE 
         ss.ss_sales_price IS NOT NULL) AS total_store_sales_profit
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
