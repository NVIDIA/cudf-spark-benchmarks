WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supp_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
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
), SupplierStatistics AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_quantity,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    ss.total_quantity,
    ss.avg_supplycost,
    s.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    )
LEFT JOIN 
    SupplierStatistics ss ON ss.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON s.supp_rank = 1 AND ss.ps_partkey = s.s_suppkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size >= 10
    )
ORDER BY 
    total_customer_spent DESC,
    p.p_name;
