WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrdersWithLineItemCount AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_item_count,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.ps_availqty,
    COALESCE(SUM(oi.o_orderkey), 0) AS total_orders,
    AVG(oi.line_item_count) AS avg_line_items,
    r.r_name AS supplier_region
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
LEFT JOIN 
    OrdersWithLineItemCount oi ON ts.s_suppkey = oi.o_orderkey
LEFT JOIN 
    nation n ON ts.s_suppkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100
GROUP BY 
    p.p_partkey, p.p_name, ps.ps_availqty, r.r_name
HAVING 
    COUNT(oi.o_orderkey) > 0
ORDER BY 
    total_orders DESC, avg_line_items DESC;
