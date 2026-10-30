
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
TotalParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CASE 
            WHEN o.o_totalprice > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        orders o
    WHERE 
        EXISTS (
            SELECT 1
            FROM lineitem l
            WHERE l.l_orderkey = o.o_orderkey AND l.l_discount < 0.1
        )
)
SELECT 
    n.n_name,
    p.p_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS return_revenue,
    COALESCE(MAX(ts.total_available_qty), 0) AS max_available_qty,
    ARRAY_AGG(DISTINCT s.s_name) FILTER (WHERE rs.rank <= 3) AS top_suppliers,
    COUNT(DISTINCT ho.o_orderkey) AS high_value_order_count
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    TotalParts ts ON ts.ps_partkey = p.p_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = l.l_orderkey
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size BETWEEN 1 AND 20
    AND n.n_nationkey NOT IN (
        SELECT 
            n2.n_nationkey
        FROM 
            nation n2
        WHERE 
            n2.n_name IN ('GERMANY', 'FRANCE')
    )
GROUP BY 
    n.n_name, p.p_name
HAVING 
    MAX(l.l_tax) IS NOT NULL 
    AND SUM(l.l_discount) < 0.5
ORDER BY 
    return_revenue DESC, n.n_name, p.p_name
LIMIT 50;
