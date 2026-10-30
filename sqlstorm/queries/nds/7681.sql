
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_item_sk) AS item_count
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 0
)
SELECT 
    tc.sales_rank,
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    cd.cd_gender,
    hd.hd_buy_potential
FROM 
    TopCustomers tc
JOIN customer c ON tc.c_customer_id = c.c_customer_id
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
