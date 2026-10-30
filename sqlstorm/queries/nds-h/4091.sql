
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
        )
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name
)
SELECT 
    H.o_orderkey,
    H.o_totalprice,
    H.o_orderdate,
    H.c_name,
    COUNT(DISTINCT PS.ps_partkey) AS distinct_parts,
    SUM(PS.ps_supplycost) AS total_supplycost,
    R.s_name AS top_supplier
FROM 
    HighValueOrders H
LEFT JOIN 
    partsupp PS ON H.o_orderkey = PS.ps_partkey
LEFT JOIN 
    RankedSuppliers R ON R.rnk = 1 AND H.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_returnflag = 'N'
    )
WHERE 
    H.lineitem_count > 5 
    AND (H.o_orderdate BETWEEN '1997-06-01' AND '1997-08-31' OR H.o_orderdate IS NULL)
GROUP BY 
    H.o_orderkey, H.o_totalprice, H.o_orderdate, H.c_name, R.s_name
HAVING 
    SUM(PS.ps_supplycost) IS NOT NULL
ORDER BY 
    H.o_totalprice DESC
LIMIT 10;
