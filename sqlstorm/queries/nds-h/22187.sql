WITH RecursiveCTE AS (
    SELECT 
        n.n_name,
        SUM(ps.ps_supplycost * li.l_quantity) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * li.l_quantity) DESC) AS rn
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        n.n_name
),
FilteredData AS (
    SELECT 
        r.r_name,
        c.c_mktsegment,
        d.total_cost,
        CASE 
            WHEN d.total_cost > 100000 THEN 'High Value'
            WHEN d.total_cost BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS cost_category
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        RecursiveCTE d ON n.n_name = d.n_name
    WHERE 
        c.c_acctbal IS NOT NULL OR c.c_comment LIKE '%Preferred%'
)
SELECT 
    fd.r_name,
    fd.c_mktsegment,
    COUNT(fd.cost_category) AS category_count,
    SUM(fd.total_cost) AS total_value
FROM 
    FilteredData fd
FULL OUTER JOIN (
    SELECT 
        r.r_name,
        NULL AS c_mktsegment,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
) rj ON fd.r_name = rj.r_name
GROUP BY 
    fd.r_name,
    fd.c_mktsegment
HAVING 
    SUM(fd.total_cost) IS NOT NULL AND 
    COALESCE(MAX(fd.total_cost), 0) > 0
ORDER BY 
    fd.r_name ASC, 
    category_count DESC NULLS LAST;
