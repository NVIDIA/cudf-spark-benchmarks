
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_discount_amt,
        SUM(cs.cs_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM 
        catalog_sales cs
    JOIN 
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        cs.cs_item_sk, cs.cs_order_number, cs.cs_sales_price, cs.cs_ext_discount_amt
),
TopSales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(RS.total_quantity, 0) AS total_quantity,
        COALESCE(RS.cs_sales_price, 0) AS sales_price
    FROM 
        item
    LEFT JOIN 
        RankedSales RS ON item.i_item_sk = RS.cs_item_sk AND RS.sales_rank <= 10
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    SUM(ts.total_quantity) AS total_sold_quantity,
    AVG(ts.sales_price) AS avg_sales_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    TopSales ts ON c.c_customer_sk = ts.i_item_sk
GROUP BY 
    ca.ca_city, ca.ca_state
ORDER BY 
    total_sold_quantity DESC
LIMIT 20;
