
WITH address_summary AS (
    SELECT
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND 
        ca_state IS NOT NULL
    GROUP BY 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), 
        ca_city, 
        ca_state
),
gender_summary AS (
    SELECT
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
purchase_summary AS (
    SELECT
        c.c_customer_sk,
        SUM(CASE 
                WHEN ws_wholesale_cost IS NOT NULL THEN ws_wholesale_cost
                ELSE 0 
            END) AS total_wholesale_cost,
        SUM(CASE 
                WHEN ws_sales_price IS NOT NULL THEN ws_sales_price
                ELSE 0 
            END) AS total_sales_price
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    g.cd_gender,
    g.gender_count,
    p.c_customer_sk,
    p.total_wholesale_cost,
    p.total_sales_price,
    CASE 
        WHEN p.total_sales_price > p.total_wholesale_cost THEN 'Profit'
        ELSE 'Loss'
    END AS profit_loss_indicator
FROM 
    address_summary a
JOIN 
    gender_summary g ON g.gender_count > 0
JOIN 
    purchase_summary p ON p.c_customer_sk IS NOT NULL
WHERE 
    a.address_count > 1
ORDER BY 
    a.ca_city, 
    a.ca_state, 
    g.cd_gender;
