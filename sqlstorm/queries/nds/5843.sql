
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.ws_item_sk, i.i_category
), TopSellingItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales,
        i.i_item_desc,
        i.i_brand
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
), CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_customer_id,
    cs.total_orders,
    cs.total_spent,
    t.total_sales AS top_sales_value,
    t.i_item_desc,
    t.i_brand
FROM 
    CustomerSales cs
JOIN 
    TopSellingItems t ON cs.total_spent > t.total_sales
JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
ORDER BY 
    cs.total_spent DESC, cs.total_orders DESC
LIMIT 100;
