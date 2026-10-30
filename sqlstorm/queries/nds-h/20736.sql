
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 5
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        o.o_totalprice > 5000
),
NationRevenue AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    n.n_name,
    COALESCE(SUM(tr.total_revenue), 0) AS nation_revenue,
    ARRAY_AGG(DISTINCT ts.s_name) AS top_suppliers,
    COALESCE(AVG(hvo.o_totalprice), 0) AS avg_high_value_order
FROM 
    nation n
LEFT JOIN 
    NationRevenue tr ON n.n_nationkey = tr.n_nationkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
WHERE 
    n.n_name LIKE '%land%'
GROUP BY 
    n.n_name
ORDER BY 
    nation_revenue DESC, avg_high_value_order ASC
LIMIT 10;
