WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_sales_price) AS total_sales_revenue,
        RANK() OVER (ORDER BY SUM(cs_sales_price) DESC) AS revenue_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 2459773 AND 2459783 
    GROUP BY 
        cs_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        r.total_quantity_sold,
        r.total_sales_revenue
    FROM 
        RankedSales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    WHERE 
        r.revenue_rank <= 10  
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity_purchased,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459773 AND 2459783
    GROUP BY 
        c.c_customer_id
)
SELECT 
    t.i_product_name AS Top_Product,
    COUNT(DISTINCT cs.c_customer_id) AS Unique_Customers,
    MAX(cs.total_spent) AS Highest_Spending,
    SUM(cs.total_quantity_purchased) AS Total_Quantity_Sold
FROM 
    TopSellingItems t
JOIN 
    CustomerStats cs ON cs.total_quantity_purchased > 0
GROUP BY 
    t.i_product_name
ORDER BY 
    Total_Quantity_Sold DESC;