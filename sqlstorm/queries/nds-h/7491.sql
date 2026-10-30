WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
), RegionCounts AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT hc.c_custkey) AS high_value_customers,
    SUM(CASE WHEN rs.rnk = 1 THEN 1 ELSE 0 END) AS top_suppliers,
    rc.nation_count
FROM 
    HighValueCustomers hc
JOIN 
    RankedSupplier rs ON hc.c_custkey = rs.s_suppkey 
JOIN 
    region r ON rs.s_suppkey = (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps
                                 JOIN part p ON ps.ps_partkey = p.p_partkey
                                 WHERE p.p_container = 'SM CASE' LIMIT 1) 
JOIN 
    RegionCounts rc ON r.r_name = rc.r_name
GROUP BY 
    r.r_name, rc.nation_count
ORDER BY 
    region;