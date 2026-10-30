
WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        MAX(p.p_retailprice) AS max_part_price
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegionSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    co.avg_order_value,
    sp.s_suppkey,
    sp.s_name,
    sp.total_available_quantity,
    sp.part_count,
    sp.max_part_price,
    nr.region_name,
    nr.supplier_count
FROM 
    CustomerOrderSummary co
JOIN 
    SupplierPartDetails sp ON co.order_count > 0 AND sp.total_available_quantity > 0
LEFT JOIN 
    NationRegionSummary nr ON co.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
    )
WHERE 
    co.total_spent > 1000 AND (sp.max_part_price IS NULL OR sp.max_part_price < 200)
ORDER BY 
    co.total_spent DESC, sp.part_count ASC;
