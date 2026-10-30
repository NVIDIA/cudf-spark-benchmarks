
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000 AND 30000
    GROUP BY 
        ws.ws_item_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
    WHERE 
        sd.total_quantity > 100
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid_inc_tax) AS customer_sales_total
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk
),
final_summary AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        cs.customer_sales_total
    FROM 
        top_sales ts
    LEFT JOIN 
        customer_sales cs ON ts.ws_item_sk = cs.c_customer_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    COALESCE(fs.total_sales, 0) AS total_sales,
    COALESCE(fs.customer_sales_total, 0) AS customer_sales_total,
    (fs.total_sales - fs.customer_sales_total) AS profit_loss,
    CASE 
        WHEN fs.total_sales > fs.customer_sales_total THEN 'Profit'
        WHEN fs.total_sales < fs.customer_sales_total THEN 'Loss'
        ELSE 'Break-even'
    END AS sales_status
FROM 
    final_summary fs
WHERE 
    fs.total_sales IS NOT NULL
ORDER BY 
    fs.total_sales DESC
LIMIT 50;
