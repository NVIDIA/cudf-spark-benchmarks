
WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_supplycost < 100) AS low_cost_count,
        CASE 
            WHEN p.p_size = 0 THEN 'Undefined Size'
            ELSE CAST(p.p_size AS STRING)
        END AS adjusted_size
    FROM 
        part p
    WHERE 
        p.p_retailprice > 500
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year' OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', p.p_retailprice, ')'), '; ') AS part_details,
    cs.total_spent,
    rs.s_name AS top_supplier
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    high_value_parts p ON l.l_partkey = p.p_partkey
JOIN 
    ranked_suppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.supplier_rank = 1
LEFT JOIN 
    customer_orders cs ON c.c_custkey = cs.c_custkey
WHERE 
    l.l_shipdate IS NOT NULL 
    AND l.l_returnflag = 'N'
GROUP BY 
    r.r_name, cs.total_spent, rs.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_orders DESC;
