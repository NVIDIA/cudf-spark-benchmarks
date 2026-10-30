WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(s.s_acctbal) AS total_supplier_balance,
        COUNT(DISTINCT n.n_nationkey) AS total_nations,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_supplier_balance,
        total_nations,
        total_parts,
        RANK() OVER (ORDER BY total_supplier_balance DESC) AS rank
    FROM 
        RegionalSummary
)
SELECT 
    tr.region_name,
    tr.total_supplier_balance,
    tr.total_nations,
    tr.total_parts,
    (SELECT AVG(total_supplier_balance) FROM TopRegions) AS avg_supplier_balance,
    (SELECT MAX(total_parts) FROM TopRegions) AS max_parts
FROM 
    TopRegions tr
WHERE 
    tr.rank <= 5
ORDER BY 
    tr.rank;
