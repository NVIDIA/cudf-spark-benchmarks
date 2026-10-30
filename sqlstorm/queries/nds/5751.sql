
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk, 
        i.i_item_desc, 
        i.i_brand, 
        i.i_class, 
        i.i_category, 
        rs.total_quantity, 
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        cp.c_customer_id, 
        cp.total_spent
    FROM 
        CustomerPurchases cp
    WHERE 
        cp.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerPurchases
        )
)
SELECT 
    ti.i_item_desc, 
    ti.total_quantity, 
    ti.total_sales, 
    hs.c_customer_id, 
    hs.total_spent
FROM 
    TopItems ti
JOIN 
    HighSpenders hs ON ti.total_sales BETWEEN 1000 AND 10000
ORDER BY 
    ti.total_sales DESC, hs.total_spent DESC;
