
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.cd_demo_sk,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ts.rank,
    cs.order_count,
    cs.total_spent
FROM 
    TopCustomers ts
JOIN 
    CustomerStats cs ON ts.cd_demo_sk = cs.cd_demo_sk
JOIN 
    customer c ON cs.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesData sd ON cs.total_spent > sd.total_sales
WHERE 
    (ca.ca_state IS NOT NULL AND ca.ca_city IS NOT NULL)
    OR (ca.ca_state IS NULL AND ca.ca_city IS NULL)
ORDER BY 
    ts.rank
LIMIT 10;
