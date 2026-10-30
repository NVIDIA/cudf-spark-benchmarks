
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_net_sales,
        COUNT(ss.ss_ticket_number) AS purchase_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_paid_inc_tax) DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        r.c_customer_id,
        r.total_net_sales,
        r.purchase_count
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 10
),
ProductPerformance AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    tc.c_customer_id,
    tc.total_net_sales,
    tc.purchase_count,
    pp.i_item_id,
    pp.total_profit,
    pp.avg_sales_price,
    pp.order_count
FROM 
    TopCustomers tc
JOIN 
    ProductPerformance pp ON pp.order_count > 5
ORDER BY 
    tc.total_net_sales DESC, pp.total_profit DESC;
