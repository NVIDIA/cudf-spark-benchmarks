WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_within_nation
    FROM 
        supplier s
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 100000.00
), 
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rank_within_nation <= 3
    GROUP BY 
        ps.ps_partkey
),
SuspiciousOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        CASE 
            WHEN o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) THEN 'High'
            ELSE 'Normal'
        END AS order_priority
    FROM 
        orders o
    WHERE 
        NOT EXISTS (
            SELECT 1
            FROM lineitem l
            WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0.5
        )
)

SELECT 
    c.c_name,
    SUM(lt.l_extendedprice * (1 - lt.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(p.total_supply_cost) AS avg_supply_cost
FROM 
    HighValueCustomers c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem lt ON o.o_orderkey = lt.l_orderkey
LEFT JOIN 
    PartSupplierDetails p ON lt.l_partkey = p.ps_partkey
LEFT JOIN 
    SuspiciousOrders so ON o.o_orderkey = so.o_orderkey
WHERE 
    lt.l_returnflag = 'N'
    AND COALESCE(so.order_priority, 'Normal') = 'Normal'
GROUP BY 
    c.c_name
HAVING 
    SUM(lt.l_extendedprice * (1 - lt.l_discount)) > 50000
ORDER BY 
    revenue DESC
LIMIT 10 OFFSET 0;
