
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws_item_sk AS item_sk,
        total_quantity_sold,
        total_sales
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id, 
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSpending cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSpending)
)
SELECT 
    t.item_sk, 
    t.total_quantity_sold, 
    t.total_sales,
    h.c_customer_id,
    h.total_spent,
    CASE 
        WHEN h.spending_rank <= 5 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_category
FROM 
    TopSellingItems t
LEFT JOIN 
    HighValueCustomers h ON t.total_sales > 1000
WHERE 
    h.total_spent IS NOT NULL OR t.total_sales IS NOT NULL
ORDER BY 
    t.total_sales DESC, h.total_spent DESC;
