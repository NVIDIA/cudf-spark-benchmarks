
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) DESC) AS name_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
CustomerDetails AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk = rc.c_customer_sk) AS purchase_count
    FROM 
        RankedCustomers rc
    WHERE 
        rc.name_rank <= 5
)
SELECT 
    DISTINCT cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.purchase_count,
    CASE 
        WHEN cd.cd_gender = 'M' THEN CONCAT('Mr. ', cd.full_name)
        ELSE CONCAT('Ms. ', cd.full_name)
    END AS addressed_name
FROM 
    CustomerDetails cd
WHERE 
    cd.purchase_count > 0
ORDER BY 
    cd.purchase_count DESC, 
    cd.full_name;
