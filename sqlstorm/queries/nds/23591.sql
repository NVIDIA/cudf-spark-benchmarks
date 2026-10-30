
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerAddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
)
SELECT 
    c.c_customer_id,
    COALESCE(c.c_first_name, 'Unknown') AS first_name,
    COALESCE(c.c_last_name, 'Customer') AS last_name,
    CASE 
        WHEN d.d_holiday = 'Y' THEN 'Holiday'
        WHEN d.d_weekend = 'Y' THEN 'Weekend'
        ELSE 'Regular Day'
    END AS day_type,
    ad.full_address,
    RANK() OVER (PARTITION BY ad.ca_state ORDER BY (SELECT SUM(ws_ext_sales_price) 
                                                      FROM web_sales 
                                                      WHERE ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE rank = 1)
                                                      AND ws_bill_customer_sk = c.c_customer_sk)) AS state_rank
FROM 
    customer c
LEFT JOIN 
    CustomerAddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
WHERE 
    c.c_birth_month IS NOT NULL 
    AND (c.c_birth_year BETWEEN 1980 AND 1995)
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_current_hdemo_sk IS NULL)
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_state = ad.ca_state 
        AND s.s_closed_date_sk IS NULL
    )
ORDER BY 
    state_rank, last_name;
