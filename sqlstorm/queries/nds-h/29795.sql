WITH CombinedData AS (
    SELECT 
        p.p_name,
        s.s_name,
        c.c_name,
        o.o_orderkey,
        l.l_extendedprice,
        CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name) AS combined_info,
        LENGTH(CONCAT(p.p_name, ' ', s.s_name, ' ', c.c_name)) AS combined_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_size > 2 AND s.s_acctbal > 1000
),
AggregatedData AS (
    SELECT
        SUBSTRING(combined_info, 1, 10) AS short_info,
        AVG(combined_length) AS avg_length,
        COUNT(*) AS total_count
    FROM 
        CombinedData
    GROUP BY
        short_info
)
SELECT
    r_name,
    avg_length,
    total_count
FROM 
    AggregatedData ad
JOIN 
    nation n ON n.n_nationkey = (
        SELECT s_nationkey FROM supplier s
        JOIN CombinedData cd ON s.s_name = cd.s_name LIMIT 1
    )
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'N%'
ORDER BY 
    avg_length DESC;
