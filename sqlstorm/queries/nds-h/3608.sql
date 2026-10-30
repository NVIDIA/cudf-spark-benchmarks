WITH SupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighCostSuppliers AS (
    SELECT 
        sc.ps_partkey, 
        sc.ps_suppkey
    FROM 
        SupplierCost sc
    WHERE 
        sc.total_supply_cost > (
            SELECT AVG(total_supply_cost) 
            FROM SupplierCost 
        )
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_price,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    s.s_name AS supplier_name, 
    od.total_order_price,
    r.r_name AS region_name,
    CASE 
        WHEN od.total_order_price IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    COUNT(hs.ps_suppkey) AS high_cost_supplier_count
FROM 
    part p
LEFT JOIN 
    HighCostSuppliers hs ON p.p_partkey = hs.ps_partkey
LEFT JOIN 
    supplier s ON hs.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    OrderDetails od ON od.o_orderkey = (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderdate = (
            SELECT MAX(o_orderdate) 
            FROM orders 
            WHERE o_orderdate < cast('1998-10-01' as date) - INTERVAL '30 days'
        )
        LIMIT 1
    )
WHERE 
    p.p_size > 10 AND 
    (s.s_acctbal IS NOT NULL OR s.s_acctbal < 0)
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, od.total_order_price, r.r_name
ORDER BY 
    total_order_price DESC NULLS LAST;