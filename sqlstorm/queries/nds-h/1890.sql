WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost,
        ss.total_parts,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
),
NationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ts.s_name,
    ts.total_supply_cost,
    ni.region_name,
    ni.supplier_count,
    CASE 
        WHEN ts.total_parts > 5 THEN 'Diverse Supplier'
        ELSE 'Specialized Supplier'
    END AS supplier_type
FROM TopSuppliers ts
JOIN NationInfo ni ON ts.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_brand = 'BrandX'
    )
    LIMIT 1
)
WHERE ts.rank <= 10
ORDER BY ts.total_supply_cost DESC;
