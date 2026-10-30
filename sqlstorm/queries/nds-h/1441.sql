WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        COUNT(l.l_orderkey) > 5
),
SupplierOrders AS (
    SELECT 
        hs.s_suppkey, 
        hs.rnk, 
        hvo.o_orderkey, 
        hvo.total_lineitem_value
    FROM 
        RankedSuppliers hs
    LEFT JOIN 
        partsupp ps ON hs.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
)
SELECT 
    ns.n_name AS nation_name,
    SUM(so.total_lineitem_value) AS total_value,
    COUNT(DISTINCT so.o_orderkey) AS order_count
FROM 
    SupplierOrders so
JOIN 
    supplier s ON so.s_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
WHERE 
    so.rnk <= 3
GROUP BY 
    ns.n_name
ORDER BY 
    total_value DESC
LIMIT 10;