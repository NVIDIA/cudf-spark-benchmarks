WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name AS nation_name
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_totalprice > 10000 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_mktsegment
),
SupplierOrderStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        EXISTS (
            SELECT 1 
            FROM RankedSuppliers r 
            WHERE ps.ps_suppkey = r.s_suppkey 
              AND r.supplier_rank <= 3
        )
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_brand,
    p.p_name,
    COALESCE(sos.order_count, 0) AS total_orders,
    COALESCE(sos.max_order_value, 0) AS max_order_value,
    CASE 
        WHEN hvo.o_orderkey IS NOT NULL THEN 'Has High Value Order'
        ELSE 'No High Value Orders'
    END AS high_value_order_status
FROM 
    part p
LEFT JOIN 
    SupplierOrderStats sos ON p.p_partkey = sos.ps_partkey
LEFT JOIN 
    HighValueOrders hvo ON hvo.o_orderdate = (SELECT MAX(o.o_orderdate) FROM HighValueOrders o)
WHERE 
    p.p_size > 10 
    AND (p.p_comment LIKE '%fragile%' OR p.p_comment IS NULL)
ORDER BY 
    p.p_brand, total_orders DESC, max_order_value ASC;
