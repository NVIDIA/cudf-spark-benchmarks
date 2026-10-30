
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2459585 AND 2459960 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        cs.total_sales,
        cs.total_discount,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000 
),
CustomerAddressDetails AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FinalReport AS (
    SELECT 
        hvc.customer_id,
        hvc.total_sales,
        hvc.total_discount,
        hvc.order_count,
        cad.ca_city,
        cad.ca_state,
        cad.ca_country 
    FROM 
        HighValueCustomers hvc
    JOIN 
        CustomerAddressDetails cad ON hvc.customer_id = cad.c_customer_sk
)
SELECT 
    customer_id,
    total_sales,
    total_discount,
    order_count,
    ca_city,
    ca_state,
    ca_country
FROM 
    FinalReport
ORDER BY 
    total_sales DESC
LIMIT 50;
