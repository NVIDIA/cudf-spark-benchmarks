WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.order_total
    FROM 
        customer c
    JOIN 
        OrderStats o ON c.c_custkey = o.o_custkey
    WHERE 
        o.rn <= 3
)
SELECT 
    r.r_name,
    ns.total_supply_cost,
    SUM(tc.order_total) AS total_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    (SELECT 
        n.n_nationkey, 
        SUM(ss.total_supply_cost) AS total_supply_cost 
     FROM 
        nation n
     JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_suppkey
     GROUP BY 
        n.n_nationkey) ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN 
    TopCustomers tc ON n.n_nationkey = tc.c_custkey
GROUP BY 
    r.r_name, ns.total_supply_cost
HAVING 
    SUM(tc.order_total) IS NOT NULL OR ns.total_supply_cost > 10000
ORDER BY 
    r.r_name;
