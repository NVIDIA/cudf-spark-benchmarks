WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30  
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
out_of_stock_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        inv.inv_quantity_on_hand
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE 
        inv.inv_quantity_on_hand = 0
),
full_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        tc.total_orders,
        COUNT(osi.i_item_sk) AS out_of_stock_items_count,
        AVG(tc.total_sales) OVER () AS average_sales
    FROM 
        top_customers tc
    LEFT JOIN 
        out_of_stock_items osi ON tc.total_orders > 0  
    WHERE 
        tc.sales_rank <= 10  
    GROUP BY 
        tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.total_orders
)
SELECT 
    f.*, 
    CASE 
        WHEN out_of_stock_items_count > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_out_of_stock_items,
    CASE 
        WHEN total_sales > average_sales THEN 'Above Average'
        WHEN total_sales < average_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_comparison
FROM 
    full_report f
ORDER BY 
    total_sales DESC;