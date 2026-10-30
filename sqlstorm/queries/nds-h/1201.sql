WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal)
            FROM customer c2
        )
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
)
SELECT 
    r.r_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ns.parts_supplied,
    tc.total_spent
FROM 
    lineitem l
JOIN 
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierStats ns ON s.s_suppkey = ns.s_suppkey
JOIN 
    TopCustomers tc ON ro.o_clerk = tc.c_name
WHERE 
    l.l_shipdate >= '1996-01-01'
    AND l.l_returnflag = 'N'
GROUP BY 
    r.r_name, ns.parts_supplied, tc.total_spent
ORDER BY 
    total_revenue DESC
LIMIT 10;