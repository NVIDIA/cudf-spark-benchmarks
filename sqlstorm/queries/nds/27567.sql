
WITH normalized_addresses AS (
    SELECT 
        LOWER(TRIM(ca_street_name)) AS normalized_street_name,
        CA_CITY AS city,
        CA_STATE AS state,
        CA_ZIP AS zip,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        LOWER(TRIM(ca_street_name)), 
        CA_CITY, 
        CA_STATE, 
        CA_ZIP
),
gender_demo AS (
    SELECT 
        cd_gender, 
        COUNT(DISTINCT c_customer_id) AS customer_count, 
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
popular_items AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, 
        i.i_item_desc
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT  
    na.normalized_street_name, 
    na.city, 
    na.state, 
    na.zip, 
    gd.cd_gender, 
    gd.customer_count, 
    gd.total_dependents, 
    pi.i_item_id, 
    pi.i_item_desc, 
    pi.total_sales
FROM 
    normalized_addresses na
JOIN 
    gender_demo gd ON gd.cd_gender = 'F'
CROSS JOIN 
    popular_items pi
WHERE 
    na.city = 'Los Angeles' 
    AND na.state = 'CA'
ORDER BY 
    gd.customer_count DESC, 
    pi.total_sales DESC;
