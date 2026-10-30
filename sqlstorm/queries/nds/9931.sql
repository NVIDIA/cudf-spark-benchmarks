
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
        AND cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
                                   AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        cs.cs_item_sk
), TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales_quantity,
        rs.total_sales_amount,
        rs.total_orders
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.cs_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sales_quantity,
    tsi.total_sales_amount,
    tsi.total_orders,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopSellingItems tsi
JOIN 
    customer_address ca ON ca.ca_address_sk IN (
        SELECT 
            c.c_current_addr_sk
        FROM 
            customer c
        JOIN 
            store s ON s.s_store_sk = c.c_customer_sk
        WHERE 
            c.c_preferred_cust_flag = 'Y'
    )
ORDER BY 
    tsi.total_sales_amount DESC;
