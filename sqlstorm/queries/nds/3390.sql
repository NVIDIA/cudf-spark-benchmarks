
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.avg_sales_price,
        cs.purchase_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
),
TopCustomers AS (
    SELECT 
        sr.c_customer_sk,
        sr.c_first_name,
        sr.c_last_name,
        sr.total_sales,
        sr.purchase_count
    FROM 
        SalesRanked sr
    WHERE 
        sr.sales_rank <= 10
),
FrequentItems AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM 
        store_sales ss
    JOIN 
        TopCustomers tc ON ss.ss_customer_sk = tc.c_customer_sk
    GROUP BY 
        ss.ss_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
    WHERE 
        i.i_item_sk IN (SELECT fi.ss_item_sk FROM FrequentItems fi)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    id.i_item_desc,
    fi.total_quantity_sold,
    id.i_current_price,
    (fi.total_quantity_sold * id.i_current_price) AS total_revenue
FROM 
    TopCustomers tc
JOIN 
    FrequentItems fi ON tc.c_customer_sk = fi.ss_item_sk
JOIN 
    ItemDetails id ON fi.ss_item_sk = id.i_item_sk
ORDER BY 
    tc.total_sales DESC, total_revenue DESC;
