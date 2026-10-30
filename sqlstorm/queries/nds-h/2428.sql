WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS available_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s 
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l 
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey 
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        n.n_regionkey, r.r_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
),
SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.available_parts,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierStats ss 
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT 
    tr.r_name,
    sr.s_name,
    sr.available_parts,
    sr.total_supply_cost,
    co.order_count,
    co.total_spent
FROM 
    TopRegions tr 
JOIN 
    SupplierRanking sr ON sr.supplier_rank <= 3 
LEFT JOIN 
    CustomerOrders co ON co.order_count > 0
WHERE 
    (sr.total_supply_cost IS NOT NULL AND co.total_spent IS NOT NULL)
    OR (sr.total_supply_cost IS NULL AND co.total_spent IS NULL)
ORDER BY 
    tr.total_revenue DESC, sr.available_parts DESC;