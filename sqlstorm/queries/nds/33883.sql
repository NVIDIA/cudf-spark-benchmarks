
WITH  SalesCTE AS (
    SELECT 
        c.c_customer_sk AS customer_sk,
        c.c_customer_id AS customer_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        customer_sk,
        customer_id,
        total_sales,
        total_transactions
    FROM 
        SalesCTE
    WHERE 
        sales_rank <= 100
),
SalesDetails AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, d.d_year
)
SELECT 
    t.customer_id,
    t.total_sales,
    COALESCE(sd.total_web_sales, 0) AS total_web_sales,
    COALESCE(sd.total_web_profit, 0) AS total_web_profit,
    (t.total_sales - COALESCE(sd.total_web_sales, 0)) AS store_sales_difference,
    (CASE 
        WHEN t.total_sales > 0 THEN ROUND((COALESCE(sd.total_web_sales, 0) / t.total_sales) * 100, 2)
        ELSE 0 
    END) AS web_sales_percentage
FROM 
    TopCustomers t
LEFT JOIN 
    SalesDetails sd ON t.customer_sk = sd.ws_item_sk
WHERE 
    (t.total_sales > 1000 OR sd.total_web_sales IS NOT NULL)
ORDER BY 
    t.total_sales DESC, web_sales_percentage DESC;
