
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY 
        cs.cs_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_spent,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
MonthlySales AS (
    SELECT 
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS monthly_sales,
        SUM(ws.ws_quantity) AS total_units_sold
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_month_seq
)
SELECT 
    c.c_customer_id,
    cs.total_orders,
    cs.avg_spent,
    cs.unique_items_purchased,
    ms.monthly_sales,
    ms.total_units_sold,
    rs.total_quantity,
    rs.total_sales
FROM 
    CustomerStats cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
JOIN 
    MonthlySales ms ON ms.d_month_seq = EXTRACT(MONTH FROM DATE '2002-10-01')
JOIN 
    RankedSales rs ON rs.cs_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 100)
WHERE 
    cs.avg_spent > (SELECT AVG(avg_spent) FROM CustomerStats)
ORDER BY 
    cs.total_orders DESC, 
    rs.total_sales DESC
LIMIT 10;
