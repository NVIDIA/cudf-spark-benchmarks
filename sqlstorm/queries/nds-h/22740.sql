WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplyStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(p.p_retailprice) AS max_price
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    n.n_name,
    COALESCE(r.total_cost, 0) AS supplier_cost,
    COALESCE(o.o_totalprice, 0) AS order_value,
    COALESCE(s.avg_supply_cost, 0) AS average_supply_cost,
    CASE 
        WHEN s.supplier_count > 5 THEN 'High Supply'
        WHEN s.supplier_count BETWEEN 3 AND 5 THEN 'Moderate Supply'
        ELSE 'Low Supply'
    END AS supply_category
FROM 
    nation n
LEFT JOIN 
    RankedSuppliers r ON n.n_nationkey = r.s_suppkey
FULL OUTER JOIN 
    RecentOrders o ON n.n_nationkey = o.c_nationkey
LEFT JOIN 
    SupplyStats s ON r.s_suppkey = s.p_partkey
WHERE 
    (r.rank = 1 OR o.recent_rank = 1)
    AND (n.n_name IS NULL OR n.n_name LIKE 'A%')
ORDER BY 
    n.n_name, supplier_cost DESC, order_value DESC
LIMIT 100
OFFSET 10;
