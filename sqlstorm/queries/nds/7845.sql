
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rs.total_revenue,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank_sales <= 10
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    tsi.i_item_desc,
    tsi.i_brand,
    tsi.i_category,
    cs.total_spent,
    cs.total_orders
FROM 
    TopSellingItems tsi
JOIN 
    CustomerSpending cs ON cs.c_customer_sk IN (SELECT c.c_customer_sk 
                                                  FROM customer c 
                                                  WHERE c.c_current_cdemo_sk IS NOT NULL)
ORDER BY 
    tsi.total_revenue DESC, cs.total_spent DESC;
