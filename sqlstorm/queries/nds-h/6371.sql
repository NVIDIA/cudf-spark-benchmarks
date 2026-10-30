
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
), 
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_value) AS total_spent
    FROM 
        customer c
    JOIN 
        RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    si.s_name,
    si.nation_name,
    si.region_name,
    tc.c_name,
    tc.total_spent
FROM 
    SupplierInfo si
JOIN 
    partsupp ps ON si.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    RecentOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN 
    TopCustomers tc ON ro.o_custkey = tc.c_custkey
WHERE 
    si.s_acctbal > 0
AND 
    ro.total_value > 1000
ORDER BY 
    si.region_name, tc.total_spent DESC;
