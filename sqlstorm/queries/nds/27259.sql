
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StateGenderCount AS (
    SELECT 
        ca_state,
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        CustomerDetails
    GROUP BY 
        ca_state, cd_gender
),
StateGenderSummary AS (
    SELECT 
        ca_state,
        SUM(CASE WHEN cd_gender = 'M' THEN gender_count ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd_gender = 'F' THEN gender_count ELSE 0 END) AS female_count
    FROM 
        StateGenderCount
    GROUP BY 
        ca_state
),
TopStates AS (
    SELECT 
        ca_state,
        male_count,
        female_count,
        RANK() OVER (ORDER BY (male_count + female_count) DESC) AS rank
    FROM 
        StateGenderSummary
)
SELECT 
    ca_state,
    male_count,
    female_count,
    rank
FROM 
    TopStates
WHERE 
    rank <= 10
ORDER BY 
    rank;
