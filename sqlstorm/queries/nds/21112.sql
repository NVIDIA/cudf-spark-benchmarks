
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_quantity DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND c.c_birth_year <= EXTRACT(YEAR FROM DATE '2002-10-01') - 18
),
TotalSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        web_sales ws
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
FilteredAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX') 
        AND (ca.ca_city IS NOT NULL OR ca.ca_country IS NULL)
    GROUP BY 
        ca.ca_address_id, ca.ca_city
),
FinalReport AS (
    SELECT 
        ra.c_customer_id,
        ra.c_first_name,
        ra.c_last_name,
        sa.total_spent,
        fa.ca_city,
        fa.total_customers
    FROM 
        RankedSales ra
    JOIN 
        TotalSales sa ON ra.c_customer_id = sa.c_customer_id
    JOIN 
        FilteredAddresses fa ON fa.total_customers > 5
    WHERE 
        ra.rn = 1
)
SELECT 
    fr.c_customer_id,
    CONCAT(fr.c_first_name, ' ', fr.c_last_name) AS full_name,
    fr.total_spent,
    COALESCE(fr.ca_city, 'Unknown') AS city_info
FROM 
    FinalReport fr
WHERE 
    fr.total_spent > (SELECT AVG(total_spent) FROM TotalSales)
ORDER BY 
    fr.total_spent DESC,
    fr.c_customer_id
LIMIT 10;
