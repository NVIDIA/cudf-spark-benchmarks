
WITH StringBenchmark AS (
    SELECT 
        c.c_first_name AS Customer_First_Name,
        c.c_last_name AS Customer_Last_Name,
        ca.ca_city AS Address_City,
        ca.ca_state AS Address_State,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS Full_Name,
        REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', '_') AS Replace_Space_With_Underscore,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS Full_Name_Length,
        LOWER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS Full_Name_Lower,
        UPPER(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS Full_Name_Upper,
        SUBSTRING(CONCAT(c.c_first_name, ' ', c.c_last_name), 1, 10) AS Name_Substring,
        CHAR_LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS Char_Length
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('NY', 'CA') 
)
SELECT 
    Customer_First_Name,
    Customer_Last_Name,
    Address_City,
    Address_State,
    Full_Name,
    Replace_Space_With_Underscore,
    Full_Name_Length,
    Full_Name_Lower,
    Full_Name_Upper,
    Name_Substring,
    Char_Length
FROM 
    StringBenchmark
ORDER BY 
    Full_Name
LIMIT 100;
