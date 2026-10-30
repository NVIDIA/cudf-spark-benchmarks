
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS review_date,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_last_review_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
TopCustomers AS (
    SELECT 
        rc.full_name,
        rc.review_date,
        DENSE_RANK() OVER (ORDER BY rc.review_date DESC) AS review_rank
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rn = 1
)
SELECT 
    tc.full_name,
    tc.review_date,
    CASE 
        WHEN tc.review_rank <= 10 THEN 'Top Reviewer'
        ELSE 'Regular Reviewer'
    END AS reviewer_category
FROM 
    TopCustomers tc
ORDER BY 
    tc.review_rank;
