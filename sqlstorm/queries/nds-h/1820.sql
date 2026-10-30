WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
), 
SupplierOrderCount AS (
    SELECT 
        s.s_suppkey,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.s_name, 
    r.s_acctbal,
    coalesce(h.lineitem_count, 0) AS high_value_order_count,
    s.order_count,
    r.rank
FROM 
    RankedSuppliers r
LEFT JOIN 
    HighValueOrders h ON r.s_suppkey = h.o_orderkey
JOIN 
    SupplierOrderCount s ON r.s_suppkey = s.s_suppkey
WHERE 
    r.rank = 1
ORDER BY 
    r.s_acctbal DESC NULLS LAST;
