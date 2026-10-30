
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 500000
),
CriticalLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        l.l_orderkey, l.l_partkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    CO.c_custkey, 
    CO.c_name, 
    HVS.s_suppkey, 
    HVS.s_name, 
    CLI.l_orderkey, 
    CLI.l_partkey, 
    CLI.revenue
FROM 
    CustomerOrders CO
JOIN 
    HighValueSuppliers HVS ON CO.total_spent > 20000
JOIN 
    CriticalLineItems CLI ON CO.c_custkey IN (
        SELECT DISTINCT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey IN (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name = 'Europe'
        )
    )
WHERE 
    CLI.revenue > 15000
ORDER BY 
    CO.total_spent DESC, CLI.revenue DESC;
