
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sub.total_orders, 0) AS total_orders,
    COALESCE(sub.total_spent, 0) AS total_spent,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(ps.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(ps.total_suppliers, 0) AS total_suppliers,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Premium'
        ELSE 'Standard'
    END AS price_category
FROM 
    part p
LEFT JOIN 
    CustomerOrders sub ON sub.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1) 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 50)
LEFT JOIN 
    PartSupplier ps ON p.p_partkey = ps.ps_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
ORDER BY 
    p.p_partkey;
