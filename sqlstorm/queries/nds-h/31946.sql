WITH  SupplyChain AS (
    SELECT 
        ps_partkey, 
        SUM(ps_availqty) AS total_available, 
        SUM(ps_supplycost) AS total_cost 
    FROM 
        partsupp 
    GROUP BY 
        ps_partkey
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
NationSuppliers AS (
    SELECT 
        n.n_nationkey, 
        SUM(s.s_acctbal) AS total_balance 
    FROM 
        nation n 
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey 
    GROUP BY 
        n.n_nationkey
)
SELECT 
    p.p_name, 
    rc.r_name, 
    ns.total_balance, 
    co.order_count, 
    co.total_spent,
    sc.total_available,
    sc.total_cost,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY rc.r_name ORDER BY co.total_spent DESC) AS rank
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region rc ON n.n_regionkey = rc.r_regionkey 
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = s.s_suppkey
LEFT JOIN 
    SupplyChain sc ON sc.ps_partkey = p.p_partkey
LEFT JOIN 
    NationSuppliers ns ON ns.n_nationkey = n.n_nationkey
WHERE 
    (co.total_spent > 1000 OR co.total_spent IS NULL)
    AND (sc.total_available > 0 AND sc.total_cost < 50)
ORDER BY 
    rc.r_name, rank;
