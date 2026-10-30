WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_mfgr ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
        AND s.s_acctbal IS NOT NULL
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),

FilteredCustomers AS (
    SELECT 
        cu.c_custkey,
        cu.order_count,
        cu.total_spent
    FROM 
        CustomerOrders cu
    WHERE 
        cu.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
        OR cu.order_count > 10
),

SupplierOptions AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        rs.rnk <= 3
    GROUP BY 
        rs.s_suppkey, rs.s_name, rs.s_acctbal
)

SELECT 
    cu.c_custkey,
    cu.order_count,
    cu.total_spent,
    so.s_name AS supplier_name,
    so.part_count
FROM 
    FilteredCustomers cu
LEFT JOIN 
    SupplierOptions so ON cu.c_custkey % 5 = so.s_suppkey % 5
WHERE 
    (cu.order_count > 0 OR so.part_count IS NOT NULL)
    AND EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = cu.c_custkey AND o.o_orderstatus = 'O')
ORDER BY 
    cu.total_spent DESC, cu.c_custkey
LIMIT 100;
