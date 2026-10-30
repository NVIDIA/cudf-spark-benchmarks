
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
        AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(CASE WHEN ts.s_acctbal IS NOT NULL THEN ts.s_acctbal ELSE 0 END), 0) AS total_acct_balance,
    MAX(p.p_retailprice) AS max_price,
    MIN(p.p_retailprice) AS min_price,
    COUNT(DISTINCT ts.s_suppkey) AS unique_top_suppliers,
    ROUND(AVG(CASE WHEN od.order_count > 0 THEN od.total_revenue / od.order_count END), 2) AS avg_revenue_per_order
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
LEFT JOIN 
    OrderDetails od ON ps.ps_partkey = od.o_orderkey
GROUP BY 
    ps.ps_partkey, p.p_name
HAVING 
    COALESCE(SUM(od.total_revenue), 0) > 1000.00
ORDER BY 
    total_revenue DESC, p.p_name ASC;
