WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_container,
        CASE 
            WHEN p.p_size > 0 THEN p.p_size / NULLIF(NULLIF(p.p_size, 0), 0) 
            ELSE 0 
        END AS adjusted_size
    FROM 
        part p
    WHERE 
        EXISTS (SELECT 1 
                FROM partsupp ps 
                WHERE ps.ps_partkey = p.p_partkey 
                AND ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
               )
),
NationSupplier AS (
    SELECT 
        n.n_name,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        orders o ON s.s_suppkey = o.o_custkey
    GROUP BY 
        n.n_name, s.s_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 0
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    ns.n_name AS supplier_nation,
    ns.s_name AS supplier_name,
    SUM(COALESCE(lp.l_extendedprice, 0) * (1 - lp.l_discount)) AS total_revenue,
    COUNT(DISTINCT lp.l_orderkey) AS unique_orders
FROM 
    FilteredParts fp
JOIN 
    lineitem lp ON lp.l_partkey = fp.p_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = lp.l_suppkey
LEFT JOIN 
    NationSupplier ns ON ns.s_name = rs.s_name
WHERE 
    fp.adjusted_size IS NOT null
    AND (ns.order_count > 5 OR ns.order_count IS NULL) 
GROUP BY 
    fp.p_partkey, fp.p_name, ns.n_name, ns.s_name
ORDER BY 
    total_revenue DESC, fp.p_name ASC
LIMIT 50 OFFSET 10;