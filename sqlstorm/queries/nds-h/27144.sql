WITH RankedNames AS (
    SELECT 
        p_name,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(p_name, 1, 5) ORDER BY LENGTH(p_name) DESC) AS rnk
    FROM 
        part
    WHERE 
        p_name LIKE '%wood%'
),
NationSummary AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT c.c_custkey) AS total_customers, 
        SUM(c.c_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
PopularContainers AS (
    SELECT 
        p_container, 
        COUNT(*) AS count_of_parts
    FROM 
        part
    WHERE 
        p_container IS NOT NULL 
    GROUP BY 
        p_container 
    ORDER BY 
        count_of_parts DESC 
    LIMIT 5
)
SELECT 
    rn.p_name AS part_name,
    ns.nation_name,
    ns.total_customers,
    pc.p_container,
    pc.count_of_parts
FROM 
    RankedNames rn
JOIN 
    NationSummary ns ON ns.total_customers > 100
JOIN 
    PopularContainers pc ON rn.p_name LIKE CONCAT('%', pc.p_container, '%')
WHERE 
    rn.rnk <= 10
ORDER BY 
    ns.total_account_balance DESC, rn.p_name;
