
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_current_addr_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0)) AS total_store_sales,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_current_addr_sk
),
high_value_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_current_addr_sk,
        (cs.total_store_sales + cs.total_web_sales) AS total_sales
    FROM 
        customer_sales cs
    WHERE 
        (cs.total_store_sales + cs.total_web_sales) > (
            SELECT 
                AVG(total_sales)
            FROM 
                (
                    SELECT 
                        (SUM(COALESCE(ss.ss_ext_sales_price, 0)) + 
                         SUM(COALESCE(ws.ws_ext_sales_price, 0))) AS total_sales
                    FROM 
                        customer c
                    LEFT JOIN 
                        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
                    LEFT JOIN 
                        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
                    GROUP BY 
                        c.c_customer_id
                ) AS avg_sales
        )
),
address_details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_address_sk
    FROM 
        customer_address ca
)
SELECT 
    hvc.c_customer_id,
    ad.ca_address_id,
    ad.ca_city,
    ad.ca_state,
    hvc.total_sales
FROM 
    high_value_customers hvc
JOIN 
    address_details ad ON hvc.c_current_addr_sk = ad.ca_address_sk
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
