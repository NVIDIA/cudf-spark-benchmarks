
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
ProductStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RegionalData AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_region_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    ps.p_partkey,
    ps.supplier_count,
    ps.avg_supply_cost,
    ps.total_available_qty,
    COALESCE(co.total_order_value, 0) AS total_order_value,
    r.total_region_sales,
    COALESCE( (SELECT MAX(rs.rnk) FROM RankedSuppliers rs WHERE rs.s_suppkey = ps.p_partkey), 0) AS highest_rank,
    CASE 
        WHEN r.unique_customers > 100 THEN 'High'
        ELSE 'Low'
    END AS customer_density
FROM 
    ProductStats ps
LEFT JOIN 
    CustomerOrders co ON ps.p_partkey = co.o_custkey
LEFT JOIN 
    RegionalData r ON COALESCE(co.o_custkey, -1) = r.unique_customers
WHERE 
    (ps.total_available_qty > 1000 OR ps.avg_supply_cost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)) 
    AND r.total_region_sales IS NOT NULL
ORDER BY 
    ps.supplier_count DESC, r.total_region_sales DESC
LIMIT 10;
