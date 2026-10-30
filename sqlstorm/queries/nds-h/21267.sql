WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), MissingParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        COUNT(ps.ps_suppkey) = 0
), OrdersWithHighValueSupplier AS (
    SELECT 
        ho.o_orderkey,
        ho.o_custkey,
        ho.total_order_value,
        rs.s_name,
        rs.s_acctbal
    FROM 
        HighValueOrders ho
    CROSS JOIN RankedSuppliers rs
    WHERE 
        rs.rnk <= 5
)
SELECT 
    o.o_orderkey,
    o.o_custkey,
    COALESCE(o.total_order_value, 0) AS order_value,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    CASE 
        WHEN m.p_partkey IS NOT NULL THEN 'Missing Part'
        ELSE 'Available'
    END AS part_status,
    RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderkey DESC) AS order_rank
FROM 
    OrdersWithHighValueSupplier o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN MissingParts m ON l.l_partkey = m.p_partkey
GROUP BY 
    o.o_orderkey, o.o_custkey, o.total_order_value, m.p_partkey
HAVING 
    (COALESCE(o.total_order_value, 0) > 10000 OR COUNT(l.l_linenumber) > 0) 
    OR m.p_partkey IS NULL
ORDER BY 
    o.o_orderkey DESC;
