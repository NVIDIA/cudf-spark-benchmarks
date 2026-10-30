WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
sales_ranked AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_net_paid, 
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS sales_rank
    FROM 
        customer_sales cs
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        COALESCE(ad.ca_city, 'Unknown City') AS city,
        COALESCE(ad.ca_state, 'Unknown State') AS state,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single' 
        END AS marital_status,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        sales_ranked sr
    JOIN 
        customer c ON sr.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        sr.sales_rank <= 100
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_marital_status, ad.ca_city, ad.ca_state
)
SELECT 
    hvc.c_first_name, 
    hvc.c_last_name, 
    hvc.city, 
    hvc.state, 
    hvc.marital_status, 
    hvc.total_quantity
FROM 
    high_value_customers hvc
WHERE 
    hvc.total_quantity > (
        SELECT AVG(total_quantity) 
        FROM high_value_customers
    )
ORDER BY 
    hvc.marital_status DESC, hvc.total_quantity DESC;