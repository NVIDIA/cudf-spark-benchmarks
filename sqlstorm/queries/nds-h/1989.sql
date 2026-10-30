
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2 
            WHERE o2.o_orderdate >= DATE '1996-01-01'
        )
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)

SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS average_discount,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    ns.n_name AS supplier_nation,
    rs.s_name AS best_supplier
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank_within_nation = 1
WHERE 
    l.l_shipdate >= TIMESTAMP '1998-10-01 12:34:56' - INTERVAL '1 year' AND
    l.l_returnflag = 'N' AND
    o.o_orderstatus = 'O' AND
    ps.ps_availqty IS NOT NULL
GROUP BY 
    p.p_name, ns.n_name, rs.s_name
HAVING 
    SUM(l.l_quantity) > 1000 AND
    AVG(l.l_discount) < 0.1
ORDER BY 
    total_quantity DESC;
