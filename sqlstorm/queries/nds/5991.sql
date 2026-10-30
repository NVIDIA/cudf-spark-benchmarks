
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'USA'
        AND c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
ProductSales AS (
    SELECT 
        i.i_item_id,
        COUNT(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
SalesAnalysis AS (
    SELECT 
        cs.c_customer_id, 
        ps.i_item_id, 
        cs.total_sales, 
        cs.order_count, 
        ps.total_quantity_sold, 
        ps.total_sales_value
    FROM 
        CustomerSales cs
    JOIN 
        ProductSales ps ON cs.total_sales > 1000 AND ps.total_quantity_sold > 10
)
SELECT 
    sa.c_customer_id,
    sa.i_item_id,
    sa.total_sales,
    sa.order_count,
    sa.total_quantity_sold,
    sa.total_sales_value,
    RANK() OVER (PARTITION BY sa.c_customer_id ORDER BY sa.total_sales DESC) AS sales_rank
FROM 
    SalesAnalysis sa
ORDER BY 
    sa.total_sales DESC
LIMIT 100;
