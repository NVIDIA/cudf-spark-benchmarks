
WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ROW_NUMBER() OVER(PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE 'Eu%' 
        AND n.n_comment IS NOT NULL
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_fulfilled
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(COALESCE(ss.total_spent, 0)) AS avg_customer_spending,
    MAX(ss.total_fulfilled) AS max_fulfilled_orders,
    STRING_AGG(DISTINCT fr.r_name, ', ') AS supplier_regions
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.ps_partkey = p.p_partkey AND rs.rank = 1
LEFT JOIN 
    FilteredRegions fr ON rs.ps_suppkey = fr.n_nationkey
LEFT JOIN 
    CustomerOrderStats ss ON ss.c_custkey = l.l_orderkey
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size BETWEEN 10 AND 20 
    AND (l.l_returnflag = 'R' OR l.l_returnflag IS NULL)
GROUP BY 
    p.p_name, p.p_partkey
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 50;
