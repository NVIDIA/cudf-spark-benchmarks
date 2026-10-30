WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        p.p_size,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
HighPriceOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        MAX(o.o_orderdate) AS latest_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
SupplierOrderCounts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    rs.s_name,
    rs.p_name,
    rs.ps_availqty,
    rs.rank,
    ho.net_price,
    CONCAT('Supplier ', rs.s_name, ' from ', rs.supplier_nation, ' provides part ', rs.p_name) AS supplier_info,
    COALESCE(oc.order_count, 0) AS total_orders
FROM 
    RankedSuppliers rs
LEFT JOIN 
    HighPriceOrders ho ON rs.s_suppkey = ho.o_orderkey
LEFT JOIN 
    SupplierOrderCounts oc ON rs.s_suppkey = oc.s_suppkey
WHERE 
    rs.rank = 1 AND ho.latest_order_date >= '1996-01-01'
ORDER BY 
    rs.p_partkey, total_orders DESC;