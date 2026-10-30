
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type, s.s_acctbal
), FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        COUNT(*) OVER (PARTITION BY o.o_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), TotalSales AS (
    SELECT 
        f.o_custkey,
        SUM(f.net_value) AS total_net_value,
        COUNT(f.o_orderkey) AS order_count,
        SUM(CASE WHEN f.item_count > 5 THEN f.net_value ELSE NULL END) AS high_value_orders
    FROM 
        FilteredOrders f
    GROUP BY 
        f.o_custkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    ts.total_net_value,
    ts.order_count,
    ts.high_value_orders,
    COALESCE(rs.total_parts, 0) AS parts_supplied
FROM 
    customer c
LEFT JOIN 
    TotalSales ts ON c.c_custkey = ts.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON c.c_custkey = rs.s_suppkey AND rs.supplier_rank = 1 
WHERE 
    ts.total_net_value IS NOT NULL OR (ts.order_count > (SELECT AVG(order_count) FROM TotalSales WHERE total_net_value IS NOT NULL))
ORDER BY 
    ts.total_net_value DESC NULLS LAST;
